/*
 ============================================================================
 Name        : conf.h
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#ifndef QBOX_CONF_H
#define QBOX_CONF_H

extern const char* QBOX_ACCESS_KEY;
extern const char* QBOX_SECRET_KEY;

extern const char* QBOX_REDIRECT_URI;			// "<RedirectURL>"
extern const char* QBOX_AUTHORIZATION_ENDPOINT;	// "<AuthURL>"
extern const char* QBOX_TOKEN_ENDPOINT;			// "https://acc.qbox.me/oauth2/token"

extern int QBOX_PUT_TIMEOUT;					// 300000 = 300s = 5m
extern int QBOX_PUT_CHUNK_SIZE;
extern int QBOX_PUT_RETRY_TIMES;

extern const char* QBOX_IO_HOST;
extern const char* QBOX_FS_HOST;
extern const char* QBOX_RS_HOST;
extern const char* QBOX_UP_HOST;

#endif

