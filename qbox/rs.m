/*
 ============================================================================
 Name        : rs.c
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#include <zlib.h>
#include "rs.h"

/*============================================================================*/
/* func QBox_RS_PutAuth, QBox_RS_PutAuthEx */

QBox_Error QBox_RS_PutAuth(
	QBox_Client* self, QBox_RS_PutAuthRet* ret)
{
	QBox_Error err;
	cJSON* root;
	char* url = QBox_String_Concat2(QBOX_IO_HOST, "/put-auth/");

	err = QBox_Client_Call(self, &root, url);
	free(url);

	if (err.code == 200) {
		ret->url = QBox_Json_GetString(root, "url", NULL);
		ret->expiresIn = QBox_Json_GetInt64(root, "expiresIn", 0);
	}
	return err;
}

QBox_Error QBox_RS_PutAuthEx(
	QBox_Client* self, QBox_RS_PutAuthRet* ret, const char* callbackUrl, int expiresIn)
{
	QBox_Error err;
	cJSON* root;
	char* url;
	char* url2;
	char* callbackEncoded;

	char expires[32];
	QBox_snprintf(expires, 32, "%d", expiresIn);

	url = QBox_String_Concat3(QBOX_IO_HOST, "/put-auth/", expires);

	if (callbackUrl != NULL && *callbackUrl != '\0') {
		callbackEncoded = QBox_String_Encode(callbackUrl);
		url2 = QBox_String_Concat3(url, "/callback/", callbackEncoded);
		free(url);
		free(callbackEncoded);
		url = url2;
	}

	err = QBox_Client_Call(self, &root, url);
	free(url);

	if (err.code == 200) {
		ret->url = QBox_Json_GetString(root, "url", NULL);
		ret->expiresIn = QBox_Json_GetInt64(root, "expiresIn", 0);
	}
	return err;
}

/*============================================================================*/
/* func QBox_RS_Put, QBox_RS_PutFile */

QBox_Error QBox_RS_Put(
	QBox_Client* self, QBox_RS_PutRet* ret, const char* tableName, const char* key,
	const char* mimeType, QBox_Reader source, QBox_Int64 fsize, const char* customMeta)
{
	QBox_Error err;
	cJSON* root;

	char* entryURI = QBox_String_Concat3(tableName, ":", key);
	char* entryURIEncoded = QBox_String_Encode(entryURI);
	char* customMetaEncoded;
	char* mimeEncoded;
	char* url;
	char* url2;

	if (mimeType == NULL) {
		mimeType = "application/octet-stream";
	}

	mimeEncoded = QBox_String_Encode(mimeType);
	url = QBox_String_Concat(QBOX_IO_HOST, "/rs-put/", entryURIEncoded, "/mime/", mimeEncoded, NULL);
	free(mimeEncoded);
	free(entryURIEncoded);

	if (customMeta != NULL && *customMeta != '\0') {
		customMetaEncoded = QBox_String_Encode(customMeta);
		url2 = QBox_String_Concat3(url, "/meta/", customMetaEncoded);
		free(url);
		free(customMetaEncoded);
		url = url2;
	}

	err = QBox_Client_CallWithBinary(self, &root, url, source, fsize);
	free(url);

	if (err.code == 200) {
		ret->hash = QBox_Json_GetString(root, "hash", NULL);
	}
	return err;
}

QBox_Error QBox_RS_PutFile(
	QBox_Client* self, QBox_RS_PutRet* ret, const char* tableName, const char* key,
	const char* mimeType, const char* srcFile, const char* customMeta)
{
	QBox_Error err;
	QBox_Int64 fsize;
	FILE* fp = fopen(srcFile, "rb");
	if (fp == NULL) {
		err.code = -1;
		err.message = "open source file failed";
		return err;
	}
	fseek(fp, 0, SEEK_END);
	fsize = ftell(fp);
	fseek(fp, 0, SEEK_SET);
	err = QBox_RS_Put(self, ret, tableName, key, mimeType, QBox_FILE_Reader(fp), fsize, customMeta);
	fclose(fp);
	return err;
}

/*============================================================================*/
/* func QBox_RS_Get, QBox_RS_GetIfNotModified */

QBox_Error QBox_RS_Get(
	QBox_Client* self, QBox_RS_GetRet* ret, const char* tableName, const char* key, const char* attName)
{
	QBox_Error err;
	cJSON* root;

	char* entryURI = QBox_String_Concat3(tableName, ":", key);
	char* entryURIEncoded = QBox_String_Encode(entryURI);
	char* url = QBox_String_Concat3(QBOX_RS_HOST, "/get/", entryURIEncoded);
	char* urlOld;
	char* attNameEncoded;

	free(entryURI);
	free(entryURIEncoded);

	if (attName != NULL) {
		attNameEncoded = QBox_String_Encode(attName);
		urlOld = url;
		url = QBox_String_Concat3(url, "/attName/", attNameEncoded);
		free(attNameEncoded);
		free(urlOld);
	}

	err = QBox_Client_Call(self, &root, url);
	free(url);

	if (err.code == 200) {
		ret->url = QBox_Json_GetString(root, "url", "unknown");
		ret->hash = QBox_Json_GetString(root, "hash", NULL);
		ret->mimeType = QBox_Json_GetString(root, "mimeType", NULL);
		ret->fsize = QBox_Json_GetInt64(root, "fsize", 0);
		ret->expiresIn = QBox_Json_GetInt64(root, "expiresIn", 0);
	}
	return err;
}

QBox_Error QBox_RS_GetIfNotModified(
	QBox_Client* self, QBox_RS_GetRet* ret, const char* tableName, const char* key, const char* attName, const char* base)
{
	QBox_Error err;
	cJSON* root;

	char* entryURI = QBox_String_Concat3(tableName, ":", key);
	char* entryURIEncoded = QBox_String_Encode(entryURI);
	char* url = QBox_String_Concat(QBOX_RS_HOST, "/get/", entryURIEncoded, "/base/", base, NULL);
	char* urlOld;
	char* attNameEncoded;

	free(entryURI);
	free(entryURIEncoded);

	if (attName != 0) {
		attNameEncoded = QBox_String_Encode(attName);
		urlOld = url;
		url = QBox_String_Concat3(url, "/attName/", attNameEncoded);
		free(attNameEncoded);
		free(urlOld);
	}

	err = QBox_Client_Call(self, &root, url);
	free(url);

	if (err.code == 200) {
		ret->url = QBox_Json_GetString(root, "url", "unknown");
		ret->hash = QBox_Json_GetString(root, "hash", 0);
		ret->mimeType = QBox_Json_GetString(root, "mimeType", 0);
		ret->fsize = QBox_Json_GetInt64(root, "fsize", 0);
		ret->expiresIn = QBox_Json_GetInt64(root, "expiresIn", 0);
	}
	return err;
}

/*============================================================================*/
/* func QBox_RS_Stat */

QBox_Error QBox_RS_Stat(
	QBox_Client* self, QBox_RS_StatRet* ret, const char* tableName, const char* key)
{
	QBox_Error err;
	cJSON* root;

	char* entryURI = QBox_String_Concat3(tableName, ":", key);
	char* entryURIEncoded = QBox_String_Encode(entryURI);
	char* url = QBox_String_Concat3(QBOX_RS_HOST, "/stat/", entryURIEncoded);

	free(entryURI);
	free(entryURIEncoded);

	err = QBox_Client_Call(self, &root, url);
	free(url);

	if (err.code == 200) {
		ret->hash = QBox_Json_GetString(root, "hash", 0);
		ret->mimeType = QBox_Json_GetString(root, "mimeType", 0);
		ret->fsize = QBox_Json_GetInt64(root, "fsize", 0);
		ret->putTime = QBox_Json_GetInt64(root, "putTime", 0);
	}
	return err;
}

/*============================================================================*/
/* func QBox_RS_Publish, QBox_RS_Unpublish */

QBox_Error QBox_RS_Publish(QBox_Client* self, const char* tableName, const char* domain)
{
	QBox_Error err;

	char* domainEncoded = QBox_String_Encode(domain);
	char* url = QBox_String_Concat(QBOX_RS_HOST, "/publish/", domainEncoded, "/from/", tableName, NULL);
	free(domainEncoded);

	err = QBox_Client_CallNoRet(self, url);
	free(url);

	return err;
}

QBox_Error QBox_RS_Unpublish(QBox_Client* self, const char* domain)
{
	QBox_Error err;

	char* domainEncoded = QBox_String_Encode(domain);
	char* url = QBox_String_Concat3(QBOX_RS_HOST, "/unpublish/", domainEncoded);
	free(domainEncoded);

	err = QBox_Client_CallNoRet(self, url);
	free(url);

	return err;
}

/*============================================================================*/
/* func QBox_RS_Delete */

QBox_Error QBox_RS_Delete(QBox_Client* self, const char* tableName, const char* key)
{
	QBox_Error err;

	char* entryURI = QBox_String_Concat3(tableName, ":", key);
	char* entryURIEncoded = QBox_String_Encode(entryURI);
	char* url = QBox_String_Concat3(QBOX_RS_HOST, "/delete/", entryURIEncoded);

	free(entryURI);
	free(entryURIEncoded);

	err = QBox_Client_CallNoRet(self, url);
	free(url);

	return err;
}

/*============================================================================*/
/* func QBox_RS_Drop */

QBox_Error QBox_RS_Drop(QBox_Client* self, const char* tableName)
{
	QBox_Error err;

	char* url = QBox_String_Concat3(QBOX_RS_HOST, "/drop/", tableName);

	err = QBox_Client_CallNoRet(self, url);
	free(url);

	return err;
}

/*============================================================================*/

