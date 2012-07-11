/*
 ============================================================================
 Name        : oauth2.h
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#ifndef QBOX_OAUTH2_H
#define QBOX_OAUTH2_H

#include "base.h"
#include "conf.h"
#include "auth_policy.h"
#include "../cJSON/cJSON.h"
#import <Foundation/Foundation.h>

/*============================================================================*/
/* Global */

void QBox_Global_Init(long flags);
void QBox_Global_Cleanup();

/*============================================================================*/
/* type QBox_Mutex */

#if defined(_WIN32)
#include <windows.h>
typedef CRITICAL_SECTION QBox_Mutex;
#else
#include <pthread.h>
typedef pthread_mutex_t QBox_Mutex;
#endif

void QBox_Mutex_Init(QBox_Mutex* self);
void QBox_Mutex_Cleanup(QBox_Mutex* self);

void QBox_Mutex_Lock(QBox_Mutex* self);
void QBox_Mutex_Unlock(QBox_Mutex* self);

/*============================================================================*/
/* type QBox_Json */

typedef struct cJSON QBox_Json;

const char* QBox_Json_GetString(QBox_Json* self, const char* key, const char* defval);
QBox_Int64 QBox_Json_GetInt64(QBox_Json* self, const char* key, QBox_Int64 defval);

/*============================================================================*/
/* type QBox_Client */

typedef NSMutableString QBox_Header;

typedef struct _QBox_Auth_Vtable {
	QBox_Error (*Auth)(void* self, QBox_Header** header, const char* url, const char* addition, size_t addlen);
	void (*Release)(void* self);
} QBox_Auth_Vtable;

typedef struct _QBox_Client {
	//void* curl;
    NSMutableURLRequest *request;
	void* auth;
	QBox_Auth_Vtable* vptr;
	QBox_Json* root;
	QBox_Buffer b;
} QBox_Client;

void QBox_Client_InitEx(QBox_Client* self, void* auth, QBox_Auth_Vtable* vptr, size_t bufSize);
void QBox_Client_Cleanup(QBox_Client* self);

QBox_Error QBox_Client_Call(QBox_Client* self, QBox_Json** ret, const char* url);
QBox_Error QBox_Client_CallNoRet(QBox_Client* self, const char* url);
QBox_Error QBox_Client_CallWithBinary(
	QBox_Client* self, QBox_Json** ret, const char* url, QBox_Reader body, QBox_Int64 bodyLen);
QBox_Error QBox_Client_CallWithBuffer(
	QBox_Client* self, QBox_Json** ret, const char* url, const char* body, QBox_Int64 bodyLen);

/*============================================================================*/

void QBox_Client_Init(QBox_Client* self, size_t bufSize);
void QBox_Client_InitByUpToken(QBox_Client* self, const char* uptoken, size_t bufSize);

/*============================================================================*/

#endif /* QBOX_OAUTH2_H */

