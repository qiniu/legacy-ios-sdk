/*
 ============================================================================
 Name        : rs.h
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#ifndef QBOX_RS_H
#define QBOX_RS_H

#include "oauth2.h"
#include "up.h"

/*============================================================================*/
/* func QBox_RS_PutAuth, QBox_RS_PutAuthEx */

typedef struct _QBox_RS_PutAuthRet {
	const char *url;
	QBox_Int64 expiresIn;
} QBox_RS_PutAuthRet;

QBox_Error QBox_RS_PutAuth(
	QBox_Client* self, QBox_RS_PutAuthRet* ret);

QBox_Error QBox_RS_PutAuthEx(
	QBox_Client* self, QBox_RS_PutAuthRet* ret, const char* callbackUrl, int expiresIn);

/*============================================================================*/
/* func QBox_RS_Get, QBox_RS_GetIfNotModified */

typedef struct _QBox_RS_GetRet {
	const char *url;
	const char* hash;
	const char* mimeType;
	QBox_Int64 fsize;
	QBox_Int64 expiresIn;
} QBox_RS_GetRet;

QBox_Error QBox_RS_Get(
	QBox_Client* self, QBox_RS_GetRet* ret, const char* tableName, const char* key, const char* attName);

QBox_Error QBox_RS_GetIfNotModified(
	QBox_Client* self, QBox_RS_GetRet* ret, const char* tableName, const char* key, const char* attName, const char* base);

/*============================================================================*/
/* func QBox_RS_Put, QBox_RS_PutFile */

typedef struct _QBox_RS_PutRet {
	const char* hash;
} QBox_RS_PutRet;

QBox_Error QBox_RS_Put(
	QBox_Client* self, QBox_RS_PutRet* ret, const char* tableName, const char* key,
	const char* mimeType, QBox_Reader source, QBox_Int64 fsize, const char* customMeta);

QBox_Error QBox_RS_PutFile(
	QBox_Client* self, QBox_RS_PutRet* ret, const char* tableName, const char* key,
	const char* mimeType, const char* srcFile, const char* customMeta);

QBox_Error QBox_RS_ResumablePut(
	QBox_Client* self, QBox_UP_PutRet* ret, QBox_UP_Progress* prog,
	QBox_UP_FnBlockNotify blockNotify, QBox_UP_FnChunkNotify chunkNotify, void* notifyParams,
	const char* entryURI, const char* mimeType, QBox_ReaderAt f, QBox_Int64 fsize,
	const char* customMeta, const char* callbackParams);

/*============================================================================*/
/* func QBox_RS_Stat */

typedef struct _QBox_RS_StatRet {
	const char* hash;
	const char* mimeType;
	QBox_Int64 fsize;	
	QBox_Int64 putTime;
} QBox_RS_StatRet;

QBox_Error QBox_RS_Stat(
	QBox_Client* self, QBox_RS_StatRet* ret, const char* tableName, const char* key);

/*============================================================================*/
/* func QBox_RS_Publish, QBox_RS_Unpublish */

QBox_Error QBox_RS_Publish(QBox_Client* self, const char* tableName, const char* domain);
QBox_Error QBox_RS_Unpublish(QBox_Client* self, const char* domain);

/*============================================================================*/
/* func QBox_RS_Delete */

QBox_Error QBox_RS_Delete(QBox_Client* self, const char* tableName, const char* key);

/*============================================================================*/
/* func QBox_RS_Drop */

QBox_Error QBox_RS_Drop(QBox_Client* self, const char* tableName);

/*============================================================================*/

#endif /* QBOX_RS_H */

