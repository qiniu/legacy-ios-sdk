/*
 ============================================================================
 Name        : oauth2_uptoken.c
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#include "oauth2.h"

/*============================================================================*/

static QBox_Error QBox_UpTokenAuth_Auth(void* self, QBox_Header** header,
    const char* url, const char* addition, size_t addlen)
{
	QBox_Error err;

    if (*header == nil) {
        *header = [NSMutableString stringWithUTF8String:""];
    }
    
    [*header appendString:[NSString stringWithUTF8String:(const char *)self]];

	err.code    = 200;
	err.message = "OK";
	return err;
}

static void QBox_UpTokenAuth_Release(void* self)
{
	free(self);
}

/*============================================================================*/

static QBox_Auth_Vtable QBox_UpTokenAuth_Vtable = {
	QBox_UpTokenAuth_Auth,
	QBox_UpTokenAuth_Release
};

void QBox_Client_InitByUpToken(QBox_Client* self, const char* uptoken, size_t bufSize)
{
	QBox_Error err;
	char* auth = NULL;

	/* Set appropriate HTTP header */
	auth = QBox_String_Concat("UpToken ", uptoken, NULL);

	QBox_Client_InitEx(self, auth, &QBox_UpTokenAuth_Vtable, bufSize);
}

/*============================================================================*/

