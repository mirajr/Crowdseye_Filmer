//
//  KFHLSUploader.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "KFHLSUploader.h"
#import "KFS3Stream.h"
#import "KFUser.h"
#import "KFLog.h"
#import "KFAPIClient.h"
#import "KFAWSCredentialsProvider.h"
#import "KFHLSWriter.h"
#import "KFRecorder.h"
#import <AWSS3/AWSS3.h>
#import <AWSCore/AWSCore.h>
#import <AWSCore/AWSService.h>

static NSString * const kManifestKey =  @"manifest";
static NSString * const kFileNameKey = @"fileName";
static NSString * const kFileStartDateKey = @"startDate";

static NSString * const kLiveManifestFileName = @"index.m3u8";
static NSString * const kVODManifestFileName = @"vod.m3u8";
static NSString * const kMasterManifestFileName = @"playlist.m3u8";

static NSString * const kUploadStateQueued = @"queued";
static NSString * const kUploadStateFinished = @"finished";
static NSString * const kUploadStateUploading = @"uploading";
static NSString * const kUploadStateFailed = @"failed";

static NSString * const kKFS3TransferManagerKey = @"kKFS3TransferManagerKey";
static NSString * const kKFS3Key = @"kKFS3Key";


@interface KFHLSUploader()
@property (nonatomic) NSUInteger numbersOffset;
@property (nonatomic, strong) NSMutableDictionary *queuedSegments;
@property (nonatomic) NSUInteger nextSegmentIndexToUpload;
@property (nonatomic, strong) AWSS3TransferManager *transferManager;
@property (nonatomic, strong) AWSS3 *s3;
@property (nonatomic, strong) KFDirectoryWatcher *directoryWatcher;
@property (atomic, strong) NSMutableDictionary *files;
@property (nonatomic, strong) NSString *manifestPath;
@property (nonatomic) BOOL manifestReady;
@property (nonatomic, strong) NSString *finalManifestString;
@property (nonatomic) BOOL isFinishedRecording;
@property (nonatomic) BOOL hasUploadedFinalManifest;
@property (nonatomic) double uploadRateTotal;
@property (nonatomic) double uploadRateCount;
@property (nonatomic) NSString *feedID;
@end

@implementation KFHLSUploader

- (id) initWithDirectoryPath:(NSString *)directoryPath stream:(KFS3Stream *)stream {
    if (self = [super init]) {
        self.stream = stream;
        self.feedID = stream.streamID;
        self.stream.bucketName = [NSString stringWithFormat:@"crowdseye/%@", stream.streamID];
        _directoryPath = [directoryPath copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.directoryWatcher = [KFDirectoryWatcher watchFolderWithPath:_directoryPath delegate:self];
        });
        _files = [NSMutableDictionary dictionary];
        _scanningQueue = dispatch_queue_create("KFHLSUploader Scanning Queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("KFHLSUploader Callback Queue", DISPATCH_QUEUE_SERIAL);
        _queuedSegments = [NSMutableDictionary dictionaryWithCapacity:5];
        _numbersOffset = 0;
        _nextSegmentIndexToUpload = 0;
        _manifestReady = NO;
        _isFinishedRecording = NO;
        _uploadRateTotal = 0;
        _uploadRateCount = 0;
    
    
        AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1 identityPoolId:@"us-east-1:cdb87120-5f38-479d-955c-39cd27f27aac"];
        
        AWSServiceConfiguration *defaultServiceConfiguration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest1 credentialsProvider:credentialsProvider];

        [AWSS3 registerS3WithConfiguration:defaultServiceConfiguration forKey:kKFS3Key];
        
        self.transferManager = [AWSS3TransferManager defaultS3TransferManager];

        self.s3 = [AWSS3 S3ForKey:kKFS3Key];
        
        self.manifestGenerator = [[KFHLSManifestGenerator alloc] initWithTargetDuration:kHLSSegmentDurationSeconds playlistType:KFHLSManifestPlaylistTypeVOD];
    }
    return self;
}

- (void) finishedRecording {
    self.isFinishedRecording = YES;
    NSLog(@"Finish Pressed");
    [_queuedSegments removeAllObjects];
//    [_queuedSegments dealloc];
    
    if (!self.hasUploadedFinalManifest) {
        // TEL
        // Ensure the last segment is uploaded.
        // There were lots of situations where the logic throughout this class missed the last segment.
        [self uploadNextSegment];
    }
}

- (void) setUseSSL:(BOOL)useSSL {
    _useSSL = useSSL;
}

- (void) uploadNextSegment {
        
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directoryPath error:nil];
    NSUInteger tsFileCount = 0;
    for (NSString *fileName in contents) {
        if ([[fileName pathExtension] isEqualToString:@"ts"]) {
            tsFileCount++;
        }
    }
    
    DDLogDebug(@"Attempting to queue next segment... %lld", _nextSegmentIndexToUpload);
    NSMutableDictionary *segmentInfo = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
    NSString *fileName = [segmentInfo objectForKey:kFileNameKey];
    NSString *fileUploadState = [_files objectForKey:fileName];
    
    // Skip uploading files that are currently being written
    if (tsFileCount == 1 && !self.isFinishedRecording) {
        DDLogDebug(@"Skipping upload of ts file currently being recorded... %@", fileName);
        return;
    }
    
    if (![fileUploadState isEqualToString:kUploadStateQueued]) {
        DDLogDebug(@"Trying to upload file that isn't queued (is currently %@)... %@", fileUploadState, fileName);
        return;
    }
    
    [_files setObject:kUploadStateUploading forKey:fileName];
    NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
    NSString *key = [self awsKeyForStream:self.stream fileName:fileName];
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];

    uploadRequest.bucket = self.stream.bucketName;
    uploadRequest.key = key;
    uploadRequest.body = [NSURL fileURLWithPath:filePath];
//    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    __block NSDate *startUploadDate;
    uploadRequest.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        NSUInteger queuedSegmentsCount = _queuedSegments.count;
        
        if (bytesSent == totalBytesSent) {
            startUploadDate = [NSDate date];
            _uploadRateTotal = 0;
            _uploadRateCount = 0;
        } else {
            NSTimeInterval timeToUpload = [[NSDate date] timeIntervalSinceDate:startUploadDate];
            double bitsPerSecond = (totalBytesSent / timeToUpload) * 8;
            double kbps = bitsPerSecond / 1024;
            
            _uploadRateTotal += kbps;
            _uploadRateCount += 1;
            double averageUploadSpeed = _uploadRateTotal / _uploadRateCount;
            
            
            
            DDLogVerbose(@"Speed: %f kbps Average Speed: %f bytesSent: %d", kbps, averageUploadSpeed, bytesSent);
//            NSLog(@"Speed: %f kbps Average Speed: %f bytesSent: %d", kbps, averageUploadSpeed, bytesSent);

            
            if ([self.delegate respondsToSelector:@selector(uploader:didUploadPartOfASegmentAtUploadSpeed:)]) {
                [self.delegate uploader:self didUploadPartOfASegmentAtUploadSpeed:kbps];
            }
        }
    };
    
    // Set the 'uploadStartDate' here, just before being added to the queue, instead of where the segmentInfo is created
    // Gives more accurate upload speed readings
    [segmentInfo setObject:[NSDate date] forKey:kFileStartDateKey];
    
    DDLogDebug(@"Queueing ts... %@", fileName);
    
    [[self.transferManager upload:uploadRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            [self s3RequestFailedForFileName:fileName withError:task.error];
        } else {
            [self s3RequestCompletedForFileName:fileName];
        }
        return nil;
    }];
    
}

- (NSString*) awsKeyForStream:(KFS3Stream*)stream fileName:(NSString*)fileName {
    return [NSString stringWithFormat:@"%@", fileName];
}

- (void) updateManifestWithString:(NSString*)manifestString manifestName:(NSString*)manifestName {
    NSData *data = [manifestString dataUsingEncoding:NSUTF8StringEncoding];
    DDLogVerbose(@"New manifest:\n%@", manifestString);
    NSString *key = [self awsKeyForStream:self.stream fileName:manifestName];
    
    AWSS3PutObjectRequest *uploadRequest = [AWSS3PutObjectRequest new];
    uploadRequest.bucket = self.stream.bucketName;
    uploadRequest.key = key;
    uploadRequest.body = data;
//    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    uploadRequest.cacheControl = @"max-age=0";
    uploadRequest.contentLength = @(data.length);
    
    
    DDLogDebug(@"Queueing manifest... %@", manifestName);
    
    [[self.s3 putObject:uploadRequest] continueWithBlock:^id(AWSTask *task) {
        if (task.error) {
            [self s3RequestFailedForFileName:manifestName withError:task.error];
            NSLog(@"Manifest failed");
        } else {
            [self s3RequestCompletedForFileName:manifestName];
            NSLog(@"Manifest Succeeded: %@", manifestName);
        }
        return nil;
    }];
    
//    [[self.s3 putObject:uploadRequest] continueWithBlock:^id(BFTask *task) {
//        if (task.error) {
//            [self s3RequestFailedForFileName:manifestName withError:task.error];
//            NSLog(@"Manifest failed");
//        } else {
//            [self s3RequestCompletedForFileName:manifestName];
//            NSLog(@"Manifest Succeeded: %@", manifestName);
//        }
//        return nil;
//    }];
}

- (void) directoryDidChange:(KFDirectoryWatcher *)folderWatcher {
    dispatch_async(_scanningQueue, ^{
        NSError *error = nil;
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_directoryPath error:&error];
        DDLogVerbose(@"Directory changed, fileCount: %lu", (unsigned long)files.count);
        if (error) {
            DDLogError(@"Error listing directory contents");
        }
        if (!_manifestPath) {
            [self initializeManifestPathFromFiles:files];
        }
        [self detectNewSegmentsFromFiles:files];
    });
}

- (void) detectNewSegmentsFromFiles:(NSArray*)files {
    if (!_manifestPath) {
        DDLogVerbose(@"Manifest path not yet available");
        return;
    }
    [files enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        NSArray *components = [fileName componentsSeparatedByString:@"."];
        NSString *filePrefix = [components firstObject];
        NSString *fileExtension = [components lastObject];
        if ([fileExtension isEqualToString:@"ts"]) {
            NSString *uploadState = [_files objectForKey:fileName];
            if (!uploadState) {
                DDLogDebug(@"Detected ts... %@", fileName);
                NSLog(@"Detected ts...%@", fileName);
                
                NSString *manifestSnapshot = [self manifestSnapshot];
                
                [self.manifestGenerator appendFromLiveManifest:manifestSnapshot];
                NSUInteger segmentIndex = [self indexForFilePrefix:filePrefix];
                
                NSMutableDictionary *segmentInfo = [[NSMutableDictionary alloc] initWithDictionary:@{kManifestKey: manifestSnapshot,
                                                                                                     kFileNameKey: fileName }];
                [_files setObject:kUploadStateQueued forKey:fileName];
                [_queuedSegments setObject:segmentInfo forKey:@(segmentIndex)];
                [self uploadNextSegment];
            }
        } else if ([fileExtension isEqualToString:@"jpg"]) {
            [self uploadThumbnail:fileName];
        }
    }];
}

- (void) uploadThumbnail:(NSString*)fileName {
    NSString *uploadState = [_files objectForKey:fileName];
    if (![uploadState isEqualToString:kUploadStateFinished]) {
        NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
        NSString *key = [self awsKeyForStream:self.stream fileName:fileName];
        
        AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
        uploadRequest.bucket = self.stream.bucketName;
        uploadRequest.key = fileName;
        uploadRequest.body = [NSURL fileURLWithPath:filePath];
//        uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
        
        [[self.transferManager upload:uploadRequest] continueWithBlock:^id(AWSTask *task) {
            if (task.error) {
                [self s3RequestFailedForFileName:fileName withError:task.error];
            } else {
                [self s3RequestCompletedForFileName:fileName];
            }
            return nil;
        }];
    }
}

- (void) initializeManifestPathFromFiles:(NSArray*)files {
    [files enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        if ([[fileName pathExtension] isEqualToString:@"m3u8"]) {
            NSArray *components = [fileName componentsSeparatedByString:@"."];
            NSString *filePrefix = [components firstObject];
            _manifestPath = [_directoryPath stringByAppendingPathComponent:fileName];
            _numbersOffset = filePrefix.length;
            NSAssert(_numbersOffset > 0, nil);
            *stop = YES;
        }
    }];
}

- (NSString*) manifestSnapshot {
    NSString *manifestSnapshot;
    
    do {
        manifestSnapshot = [self fetchManifestSnapshotFromFile];
        
        if (manifestSnapshot == nil || [manifestSnapshot isEqualToString:@""]) {
            DDLogVerbose(@"manifestPath was nil or blank, trying again.");
        }
    } while (manifestSnapshot == nil || [manifestSnapshot isEqualToString:@""]);
    
    return manifestSnapshot;
}

- (NSString *)fetchManifestSnapshotFromFile {
    return [NSString stringWithContentsOfFile:_manifestPath encoding:NSUTF8StringEncoding error:nil];
}

- (NSUInteger) indexForFilePrefix:(NSString*)filePrefix {
    NSString *numbers = [filePrefix substringFromIndex:_numbersOffset];
    return [numbers integerValue];
}

- (NSURL*) urlWithFileName:(NSString*)fileName {
    NSString *key = [self awsKeyForStream:self.stream fileName:fileName];
    NSString *ssl = @"";
    if (self.useSSL) {
        ssl = @"s";
    }
    NSString *urlString = [NSString stringWithFormat:@"http%@://%@.s3.amazonaws.com/%@", ssl, self.stream.bucketName, key];
//    NSLog(@"%@", urlString);
    return [NSURL URLWithString:urlString];
}

- (NSURL*) manifestURL {
    NSString *manifestName = nil;
    if (self.isFinishedRecording) {
        manifestName = kVODManifestFileName;
    } else {
        manifestName = [_manifestPath lastPathComponent];
    }
    return [self urlWithFileName:manifestName];
}

-(void)s3RequestCompletedForFileName:(NSString*)fileName
{
    dispatch_async(_scanningQueue, ^{
        if ([fileName.pathExtension isEqualToString:@"m3u8"]) {
            DDLogDebug(@"Uploaded manifest... %@", fileName);
            
            dispatch_async(self.callbackQueue, ^{
                if (!_manifestReady && [fileName isEqualToString:kLiveManifestFileName]) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:liveManifestReadyAtURL:)]) {
                        [self.delegate uploader:self liveManifestReadyAtURL:[self manifestURL]];
                    }
                    _manifestReady = YES;
                }
                if (self.isFinishedRecording && _queuedSegments.count == 0 && fileName == kVODManifestFileName) {
                    self.hasUploadedFinalManifest = YES;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(uploaderHasFinished:)]) {
                        [self.delegate uploaderHasFinished:self];
                    }
                }
            });
        } else if ([fileName.pathExtension isEqualToString:@"ts"]) {
            DDLogDebug(@"Uploaded ts... %@", fileName);
            NSLog(@"File Upload Completed For: %@", fileName);
            
            NSDictionary *segmentInfo = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
            NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
            
            NSString *manifest = [segmentInfo objectForKey:kManifestKey];
            NSDate *uploadStartDate = [segmentInfo objectForKey:kFileStartDateKey];
            NSDate *uploadFinishDate = [NSDate date];
            
            NSError *error = nil;
            NSDictionary *fileStats = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
            if (error) {
                DDLogError(@"Error getting stats of path %@: %@", filePath, error);
            }
            uint64_t fileSize = [fileStats fileSize];
            
            NSTimeInterval timeToUpload = [uploadFinishDate timeIntervalSinceDate:uploadStartDate];
            double bitsPerSecond = fileSize / timeToUpload * 8;
            double kbps = bitsPerSecond / 1024;
            [_files setObject:kUploadStateFinished forKey:fileName];
            
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                DDLogError(@"Error removing uploaded segment: %@", error.description);
            }
            [_queuedSegments removeObjectForKey:@(_nextSegmentIndexToUpload)];
            NSUInteger queuedSegmentsCount = _queuedSegments.count;
            
            // Live
            [self updateManifestWithString:[self manifestSnapshot] manifestName:kLiveManifestFileName];
            
            // VOD
            if (true) {
                NSLog(@"FINALIZED MANIFEST");
                NSLog(@"Manifest Snapshot %@", [self manifestSnapshot]);
//                [self.manifestGenerator appendFromLiveManifest:[self manifestSnapshot]]; //will any be uploaded?
                [self.manifestGenerator finalizeManifest];
                [self updateManifestWithString:[self.manifestGenerator manifestString] manifestName:kVODManifestFileName];
            }
            
            // Master (Playlist)
            [self updateManifestWithString:[self.manifestGenerator masterString] manifestName:kMasterManifestFileName];
            
            _nextSegmentIndexToUpload++;
            [self uploadNextSegment];
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:didUploadSegmentAtURL:uploadSpeed:numberOfQueuedSegments:)]) {
                NSURL *url = [self urlWithFileName:fileName];
                dispatch_async(self.callbackQueue, ^{
                    [self.delegate uploader:self didUploadSegmentAtURL:url uploadSpeed:kbps numberOfQueuedSegments:queuedSegmentsCount];
                });
            }
        } else if ([fileName.pathExtension isEqualToString:@"jpg"]) {
            [self.files setObject:kUploadStateFinished forKey:fileName];
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:thumbnailReadyAtURL:)]) {
                NSURL *url = [self urlWithFileName:fileName];
                dispatch_async(self.callbackQueue, ^{
                    [self.delegate uploader:self thumbnailReadyAtURL:url];
                });
            }
            NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
            
            NSError *error = nil;
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            }
            if (error) {
                DDLogError(@"Error removing thumbnail: %@", error.description);
            }
            self.stream.thumbnailURL = [self urlWithFileName:fileName];
            [[KFAPIClient sharedClient] updateMetadataForStream:self.stream callbackBlock:^(KFStream *updatedStream, NSError *error) {
                if (error) {
                    DDLogError(@"Error updating stream thumbnail: %@", error);
                } else {
                    DDLogDebug(@"Updated stream thumbnail: %@", updatedStream.thumbnailURL);
                }
            }];
        }
    });
}

-(void)s3RequestFailedForFileName:(NSString*)fileName withError:(NSError *)error
{
    dispatch_async(_scanningQueue, ^{
        [_files setObject:kUploadStateQueued forKey:fileName];
//        NSLog(@"Failed to upload request, requeuing %@: %@", fileName, error.description);
        DDLogError(@"Failed to upload request, requeuing %@: %@", fileName, error.description);
        [self uploadNextSegment];
    });
}

@end
