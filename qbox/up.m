/*
 ============================================================================
 Name        : up.c
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#include <zlib.h>
#include "up.h"

/*============================================================================*/

static const QBox_Int64 QBOX_UP_BLOCK_SIZE = (4 * 1024 * 1024); /* Default block size is 4MB */

static QBox_Error QBox_UP_Chunkput(QBox_Client* self, QBox_UP_PutRet* ret,
    QBox_Reader body, int bodyLength, const char* url)
{
    QBox_Error err;
	char* mimeEncoded = NULL;
    char* url2 = NULL;
    char* chkBuf = NULL;
	cJSON* root = NULL;
    unsigned long chunk_crc32 = 0L;

	mimeEncoded = QBox_String_Encode("application/octet-stream");
	url2 = QBox_String_Concat(url, "/mime/", mimeEncoded, NULL);
    free(mimeEncoded);

    chkBuf = malloc(bodyLength);
    body.Read(chkBuf, 1, bodyLength, body.self);

	err = QBox_Client_CallWithBuffer(self, &root, url2, chkBuf, bodyLength);
	free(url2);

	if (err.code == 200) {
		ret->ctx = QBox_Json_GetString(root, "ctx", NULL);
		ret->checksum = QBox_Json_GetString(root, "checksum", NULL);

		ret->crc32 = QBox_Json_GetInt64(root, "crc32", 0);

        chunk_crc32 = crc32(0L, NULL, 0);
        chunk_crc32 = crc32(chunk_crc32, chkBuf, bodyLength);

        if (chunk_crc32 != ret->crc32) {
            err.code = 400;
            err.message = "Failed in verifying CRC32";
        }
        else {
            err.code = 200;
            err.message = "OK";
        }
	}

    free(chkBuf);

    return err;
}

/*============================================================================*/

QBox_Error QBox_UP_Mkblock(QBox_Client* self, QBox_UP_PutRet* ret,
    int blkSize, QBox_Reader body, int bodyLength)
{
    QBox_Error err;
    char blkSizeStr[128];
    char* url = NULL;
    
    bzero(blkSizeStr, sizeof(blkSizeStr));
    QBox_snprintf(blkSizeStr, sizeof(blkSizeStr), "%d", blkSize);
	url = QBox_String_Concat(QBOX_UP_HOST, "/mkblk/", blkSizeStr, NULL);

    err = QBox_UP_Chunkput(self, ret, body, bodyLength, url);
    free(url);

    return err;
}

/*============================================================================*/

QBox_Error QBox_UP_Blockput(QBox_Client* self, QBox_UP_PutRet* ret,
    const char* ctx, int offset, QBox_Reader body, int bodyLength)
{
    QBox_Error err;
    char offsetStr[128];
    char* url = NULL;
    
    bzero(offsetStr, sizeof(offsetStr));
    QBox_snprintf(offsetStr, sizeof(offsetStr), "%d", offset);

    url = QBox_String_Concat(QBOX_UP_HOST, "/bput/", ctx, "/", offsetStr, NULL);

    err = QBox_UP_Chunkput(self, ret, body, bodyLength, url);
    free(url);

    return err;
}

/*============================================================================*/

QBox_Error QBox_UP_ResumableBlockput(QBox_Client* self, QBox_UP_PutRet* ret,
	QBox_ReaderAt f, int blkIndex, int blkSize, int chkSize, int retryTimes,
	QBox_UP_BlockProgress* blkProg, QBox_UP_FnChunkNotify chunkNotify, void* notifyParams)
{
    QBox_Error err;
    QBox_Reader ri;
    int bodyLength = 0;
    int i = 0;
    int keepGoing = 1;

    /* Try make block and put the first chunk */
    if (blkProg->restSize == blkSize) {
        bodyLength = (blkProg->restSize > chkSize) ? chkSize : blkProg->restSize;

        ri = QBox_SectionReader(
            f,
            (blkIndex * QBOX_UP_BLOCK_SIZE) + blkProg->offset,
            bodyLength
        );

        for (i = 0; i <= retryTimes; ++i) {
            err = QBox_UP_Mkblock(self, ret, blkSize, ri, bodyLength);
            blkProg->errCode = err.code;

            if (err.code == 200) {
                blkProg->ctx       = (char*)ret->ctx;
                blkProg->restSize -= bodyLength;
                blkProg->offset   += bodyLength;

                if (chunkNotify) {
                    keepGoing = chunkNotify(notifyParams, blkIndex, blkProg);
                }

                break;
            }
        } /* for retry */

        QBox_SectionReader_Release(ri.self);

        if (err.code != 200) {
            return err;
        }
        if (keepGoing == 0) {
            err.code = 299;
            err.message = "The chunk has been put but the progress is aborted";
            return err;
        }
    } /* make block */

    /* Try put block */
    while (blkProg->restSize > 0) {
        bodyLength = (blkProg->restSize > chkSize) ? chkSize : blkProg->restSize;

        ri = QBox_SectionReader(
            f,
            (blkIndex * QBOX_UP_BLOCK_SIZE) + blkProg->offset,
            bodyLength
        );

        for (i = 0; i <= retryTimes; ++i) {
            err = QBox_UP_Blockput(self, ret, blkProg->ctx, blkProg->offset, ri, bodyLength);
            blkProg->errCode = err.code;

            if (err.code == 200) {
                blkProg->ctx       = (char*)ret->ctx;
                blkProg->restSize -= bodyLength;
                blkProg->offset   += bodyLength;

                if (chunkNotify) {
                    keepGoing = chunkNotify(notifyParams, blkIndex, blkProg);
                }

                break;
            }
        } /* for retry */

        QBox_SectionReader_Release(ri.self);

        if (err.code != 200) {
            return err;
        }
        if (keepGoing == 0) {
            err.code = 299;
            err.message = "The chunk has been put but the progress is aborted";
            return err;
        }
    } /* while putting block */

    err.code = 200;
    err.message = "OK";
    return err;
}

/*============================================================================*/

QBox_Error QBox_UP_Mkfile(
	QBox_Client* self, QBox_Json** ret,
    const char* cmd, const char* entry, const char* mimeType,
	QBox_Int64 fsize, const char* params, const char* callbackParams,
	QBox_UP_Checksum* checksums, int blkCount)
{
    QBox_Error err;
    char fsizeStr[256];
    int i = 0;
    char* cksumBuf = NULL;
    int cksumSize = 20 * blkCount;
    char* url = NULL;
    char* cksum = NULL;
    char* offset = NULL;
    char* params2 = NULL;
    char* paramsFinal = NULL;
    char* strEncoded = NULL;

    cksumBuf = calloc(20, blkCount);

    for (i = 0; i < blkCount; ++i) {
        /* Concatenate all ckecksum strings */
        offset = cksumBuf + 20 * i;
        cksum = QBox_String_Decode(checksums[i].value);
        memcpy(offset, cksum, 20);
        free(cksum);
    } /* for */

    if (params == NULL) {
        params = "";
    }

	if (mimeType == NULL) {
		mimeType = "application/octet-stream";
	}

	strEncoded = QBox_String_Encode(mimeType);
    paramsFinal = QBox_String_Concat(params, "/mimeType/", strEncoded, NULL);
    free(strEncoded);

    if (callbackParams != NULL) {
        params2 = QBox_String_Concat(paramsFinal, "/params/", callbackParams, NULL);
        free(paramsFinal);
        paramsFinal = params2;
    }

    bzero(fsizeStr, sizeof(fsizeStr));
    QBox_snprintf(fsizeStr, sizeof(fsizeStr), "%llu", fsize);

    strEncoded = QBox_String_Encode(entry);
    url = QBox_String_Concat(QBOX_UP_HOST, cmd, strEncoded, "/fsize/", fsizeStr, paramsFinal, NULL);
	free(paramsFinal);
	free(strEncoded);

	err = QBox_Client_CallWithBuffer(self, ret, url, cksumBuf, cksumSize);
	free(url);

    return err;
}

/*============================================================================*/

QBox_UP_Progress* QBox_UP_NewProgress(QBox_Int64 fsize)
{
    QBox_UP_Progress* prog = NULL;
    int i = 0;
    QBox_Int64 rest = fsize;

    prog = calloc(sizeof(*prog), 1);

    if (prog != NULL) {
        prog->blockNextIndex = 0;

        prog->blockCount = fsize / QBOX_UP_BLOCK_SIZE;
        if (fsize % QBOX_UP_BLOCK_SIZE > 0) {
            prog->blockCount += 1;
        }

        prog->checksums = calloc(sizeof(*(prog->checksums)), prog->blockCount);
        prog->progs     = calloc(sizeof(*(prog->progs)), prog->blockCount);

        for (i = 0; i < prog->blockCount; ++i) {
            prog->progs[i].restSize = (rest > QBOX_UP_BLOCK_SIZE) ? QBOX_UP_BLOCK_SIZE : rest;
            rest -= prog->progs[i].restSize;
        } /* for */
    }

    return prog;
}

void QBox_UP_Progress_Release(QBox_UP_Progress* prog)
{
    if (prog != NULL) {
        free(prog->progs);
        free(prog->checksums);
        free(prog);
    }
}

/*============================================================================*/

QBox_Error QBox_UP_Put(QBox_Client* self, QBox_UP_PutRet* ret, QBox_ReaderAt f,
    QBox_Int64 fsize, QBox_UP_Progress* prog,
	QBox_UP_FnBlockNotify blockNotify, QBox_UP_FnChunkNotify chunkNotify, void* notifyParams)
{
    QBox_Error err;
    QBox_Json* root; 
    int blkIndex = prog->blockNextIndex;
    int keepGoing = 1;

    for (; blkIndex < prog->blockCount;) {
        ret->ctx          = NULL;
        ret->checksum     = 0;
        ret->crc32        = 0;

        err = QBox_UP_ResumableBlockput(
            self,
            ret,
            f,
            blkIndex,
            prog->progs[blkIndex].offset + prog->progs[blkIndex].restSize,
            QBOX_PUT_CHUNK_SIZE,
            QBOX_PUT_RETRY_TIMES,
            &prog->progs[blkIndex],
            chunkNotify,
            notifyParams
        );

        if (err.code != 200) {
            return err;
        }

        memcpy(prog->checksums[blkIndex].value, ret->checksum, strlen(ret->checksum));

        ++prog->blockNextIndex;

        if (blockNotify) {
            keepGoing = blockNotify(notifyParams, blkIndex, &prog->checksums[blkIndex]);
        }
        if (keepGoing == 0 && prog->blockNextIndex < prog->blockCount) {
            err.code = 299;
            err.message = "The block has been put but the progress is aborted";
            return err;
        }

        blkIndex = prog->blockNextIndex;
    } /* for */

    err.code = 200;
    err.message = "OK";
    return err;
}
