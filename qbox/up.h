/*
 ============================================================================
 Name        : up.h
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#ifndef QBOX_UP_H
#define QBOX_UP_H

#include "oauth2.h"
#include <stdlib.h>

/*============================================================================*/

typedef struct _QBox_UP_BlockProgress {
	char* ctx;
	int offset;
	int restSize;
	int errCode;
} QBox_UP_BlockProgress;

typedef int (*QBox_UP_FnChunkNotify)(void* self, int blockIdx, QBox_UP_BlockProgress* prog);

typedef struct _QBox_UP_PutRet {
	const char* ctx;
	const char* checksum;
	QBox_Uint32 crc32;
} QBox_UP_PutRet;

QBox_Error QBox_UP_Mkblock(
	QBox_Client* self, QBox_UP_PutRet* ret, int blockSize, QBox_Reader body, int bodyLength);

QBox_Error QBox_UP_Blockput(
	QBox_Client* self, QBox_UP_PutRet* ret, const char* ctx, int offset, QBox_Reader body, int bodyLength);

QBox_Error QBox_UP_ResumableBlockput(
	QBox_Client* self, QBox_UP_PutRet* ret,
	QBox_ReaderAt f, int blockIdx, int blkSize, int chunkSize, int retryTimes,
	QBox_UP_BlockProgress* prog,
	QBox_UP_FnChunkNotify chunkNotify, void* notifyParams);

/*============================================================================*/

typedef struct _QBox_UP_Checksum {
	char value[28];
} QBox_UP_Checksum;

QBox_Error QBox_UP_Mkfile(
	QBox_Client* self, QBox_Json** ret,
    const char* cmd, const char* entry, const char* mimeType,
	QBox_Int64 fsize, const char* params, const char* callbackParams,
	QBox_UP_Checksum* checksums, int blockCount);

/*============================================================================*/

typedef struct _QBox_UP_Progress {
	QBox_UP_Checksum* checksums;
	QBox_UP_BlockProgress* progs;
	int blockCount;
    int blockNextIndex;
} QBox_UP_Progress;

QBox_UP_Progress* QBox_UP_NewProgress(QBox_Int64 fsize);
void QBox_UP_Progress_Release(QBox_UP_Progress* prog);

typedef int (*QBox_UP_FnBlockNotify)(void* self, int blockIdx, QBox_UP_Checksum* checksum);

QBox_Error QBox_UP_Put(
	QBox_Client* self, QBox_UP_PutRet* ret, QBox_ReaderAt f, QBox_Int64 fsize, QBox_UP_Progress* prog,
	QBox_UP_FnBlockNotify blockNotify, QBox_UP_FnChunkNotify chunkNotify, void* notifyParams);

#endif 
