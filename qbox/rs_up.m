/*
 ============================================================================
 Name        : rs_up.c
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */
 
#include "rs.h"

/*============================================================================*/

QBox_Error QBox_RS_ResumablePut(
	QBox_Client* self, QBox_UP_PutRet* ret, QBox_UP_Progress* prog,
	QBox_UP_FnBlockNotify blockNotify, QBox_UP_FnChunkNotify chunkNotify, void* notifyParams,
	const char* entryURI, const char* mimeType, QBox_ReaderAt f, QBox_Int64 fsize,
	const char* customMeta, const char* callbackParams)
{
    QBox_Error err;
    QBox_Json* root = NULL;
    char* params = NULL;

    err = QBox_UP_Put(self, ret, f, fsize, prog, blockNotify, chunkNotify, notifyParams);
    if (err.code != 200) {
        return err;
    }

    if (customMeta != NULL) {
        params = QBox_String_Concat("/meta/", customMeta, NULL);
    }

    err = QBox_UP_Mkfile(
        self,
        &root,
        "/rs-mkfile/",
        entryURI,
        mimeType,
        fsize,
        params,
        callbackParams,
        prog->checksums,
        prog->blockCount
    );
    free(params);

    return err;
}

/*============================================================================*/

