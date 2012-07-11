/*
 ============================================================================
 Name        : oauth2.c
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#include "oauth2.h"
#include <string.h>
#include <stdlib.h>

/*============================================================================*/
/* type QBox_Mutex */

#if defined(_WIN32)

void QBox_Mutex_Init(QBox_Mutex* self)
{
	InitializeCriticalSection(self);
}

void QBox_Mutex_Cleanup(QBox_Mutex* self)
{
	DeleteCriticalSection(self);
}

void QBox_Mutex_Lock(QBox_Mutex* self)
{
	EnterCriticalSection(self);
}

void QBox_Mutex_Unlock(QBox_Mutex* self)
{
	LeaveCriticalSection(self);
}

#else

void QBox_Mutex_Init(QBox_Mutex* self)
{
	pthread_mutex_init(self, NULL);
}

void QBox_Mutex_Cleanup(QBox_Mutex* self)
{
	pthread_mutex_destroy(self);
}

void QBox_Mutex_Lock(QBox_Mutex* self)
{
	pthread_mutex_lock(self);
}

void QBox_Mutex_Unlock(QBox_Mutex* self)
{
	pthread_mutex_unlock(self);
}

#endif

/*============================================================================*/
/* Global */

void QBox_Global_Init(long flags)
{
}

void QBox_Global_Cleanup()
{
}

/*============================================================================*/
/* func QBox_call */

static const char g_statusCodeError[] = "http status code is not OK";

static QBox_Error QBox_callex(NSMutableURLRequest* request, QBox_Buffer *resp, QBox_Json** ret, QBox_Bool simpleError)
{
	QBox_Error err;
	long httpCode;
	QBox_Json* root;

    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] init];
    NSError* error;
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

	if (response != nil) {
        httpCode = [response statusCode];
		if (returnData != nil) {
            NSString *responseString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
			root = cJSON_Parse([responseString cStringUsingEncoding:NSUTF8StringEncoding]);
		} else {
			root = NULL;
		}
		*ret = root;
		err.code = (int)httpCode;
		if (httpCode / 100 != 2) {
			if (simpleError) {
				err.message = g_statusCodeError;
			} else {
				err.message = QBox_Json_GetString(root, "error", g_statusCodeError);
			}
		} else {
			err.message = "OK";
		}
	} else {
		*ret = NULL;
        err.code = 400;
        if (error != nil) {
            err.message = [error.description cStringUsingEncoding:NSUTF8StringEncoding];
        } else {
            err.message = "Failed performing HTTP request.";
        }
	}

	return err;
}

QBox_Error QBox_call(NSMutableURLRequest *request, int bufSize, QBox_Json** ret, QBox_Bool simpleError)
{
	QBox_Error err;
	QBox_Buffer resp;
	QBox_Buffer_Init(&resp, bufSize);

	err = QBox_callex(request, &resp, ret, simpleError);

	QBox_Buffer_Cleanup(&resp);
	return err;
}

/*============================================================================*/
/* type QBox_Json */

const char* QBox_Json_GetString(QBox_Json* self, const char* key, const char* defval)
{
	QBox_Json* sub;
	if (self == NULL) {
		return defval;
	}
	sub = cJSON_GetObjectItem(self, key);
	if (sub != NULL && sub->type == cJSON_String) {
		return sub->valuestring;
	} else {
		return defval;
	}
}

QBox_Int64 QBox_Json_GetInt64(QBox_Json* self, const char* key, QBox_Int64 defval)
{
	QBox_Json* sub;
	if (self == NULL) {
		return defval;
	}
	sub = cJSON_GetObjectItem(self, key);
	if (sub != NULL && sub->type == cJSON_Number) {
		return (QBox_Int64)sub->valuedouble;
	} else {
		return defval;
	}
}

/*============================================================================*/
/* type QBox_Client */

void QBox_Client_InitEx(QBox_Client* self, void* auth, QBox_Auth_Vtable* vptr, size_t bufSize)
{
	self->root = NULL;
	self->auth = auth;
    self->vptr = vptr;

	QBox_Buffer_Init(&self->b, bufSize);
}

void QBox_Client_Cleanup(QBox_Client* self)
{
	if (self->auth != NULL) {
		self->vptr->Release(self->auth);
		self->auth = NULL;
	}
	if (self->request != NULL) {
        [self->request release];
		self->request = NULL;
	}
	if (self->root != NULL) {
		cJSON_Delete(self->root);
		self->root = NULL;
	}
	QBox_Buffer_Cleanup(&self->b);
}

static void QBox_Client_initcall(QBox_Client* self, const char* url)
{
	QBox_Buffer_Reset(&self->b);
	if (self->root != NULL) {
		cJSON_Delete(self->root);
		self->root = NULL;
	}
    
    NSString* cocoaURL = [NSString stringWithUTF8String:url];
    
    if (self->request != nil){
        [self->request release];
    }
    self->request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:cocoaURL]];

    [self->request setHTTPMethod:@"POST"];
}

static QBox_Error QBox_Client_callWithBody(
	QBox_Client* self, QBox_Json** ret, const char* url, QBox_Int64 bodyLen,
    NSMutableURLRequest *request, QBox_Header* headers)
{
	QBox_Error err;

    [request setValue:[NSString stringWithFormat:@"%lld", bodyLen] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];

	err = self->vptr->Auth(self->auth, &headers, url, NULL, 0);
	if (err.code != 200) {
		return err;
	}
    
    //NSLog(@"Authorization: %@", headers);
    [request setValue:headers forHTTPHeaderField:@"Authorization"];

	err = QBox_callex(request, &self->b, &self->root, QBox_False);

	*ret = self->root;
	return err;
}

QBox_Error QBox_Client_CallWithBinary(
	QBox_Client* self, QBox_Json** ret, const char* url, QBox_Reader body, QBox_Int64 bodyLen)
{
    QBox_Header* headers = NULL;

	QBox_Client_initcall(self, url);

	return QBox_Client_callWithBody(self, ret, url, bodyLen, self->request, headers);
}

QBox_Error QBox_Client_CallWithBuffer(
	QBox_Client* self, QBox_Json** ret, const char* url, const char* body, QBox_Int64 bodyLen)
{
    QBox_Header* headers = NULL;

	QBox_Client_initcall(self, url);

    NSData *postData = [NSData dataWithBytes:body length:bodyLen];
    NSString* postLength = [NSString stringWithFormat:@"%lld", bodyLen];
    
    [self->request setValue:postLength forHTTPHeaderField:@"Content-Length"];  
    [self->request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];  
    [self->request setHTTPBody:postData];

	return QBox_Client_callWithBody(self, ret, url, bodyLen, self->request, headers);
}

QBox_Error QBox_Client_Call(QBox_Client* self, QBox_Json** ret, const char* url)
{
	QBox_Error err;
	QBox_Header* headers = NULL;

	QBox_Client_initcall(self, url);

	err = self->vptr->Auth(self->auth, &headers, url, NULL, 0);
	if (err.code != 200) {
		return err;
	}

    [self->request setValue:headers forHTTPHeaderField:@"Authorization"];

	err = QBox_callex(self->request, &self->b, &self->root, QBox_False);
	*ret = self->root;
	return err;
}

QBox_Error QBox_Client_CallNoRet(QBox_Client* self, const char* url)
{
	QBox_Error err;
	QBox_Header* headers = NULL;

	QBox_Client_initcall(self, url);

	err = self->vptr->Auth(self->auth, &headers, url, NULL, 0);
	if (err.code != 200) {
		return err;
	}
    
    [self->request setValue:headers forHTTPHeaderField:@"Authorization"];

	return QBox_callex(self->request, &self->b, &self->root, QBox_False);
}

