/*
 ============================================================================
 Name        : auth_policy.c
 Author      : Qiniu Developers
 Version     : 1.0.0.0
 Copyright   : 2012(c) Shanghai Qiniu Information Technologies Co., Ltd.
 Description : 
 ============================================================================
 */

#include "auth_policy.h"
#include "conf.h"
#include "base.h"
#include <stdlib.h>
#include <time.h>
#include "../cJSON/cJSON.h"
#import <CommonCrypto/CommonHMAC.h>

static char* QBox_AuthPolicy_json(const QBox_AuthPolicy* auth)
{
	int expires;
	time_t deadline;
	char* authstr;
	cJSON *root = cJSON_CreateObject();

	if (auth->scope) {
		cJSON_AddStringToObject(root, "scope", auth->scope);
	}
	if (auth->callbackUrl) {
		cJSON_AddStringToObject(root, "callbackUrl", auth->callbackUrl);
	}
	if (auth->returnUrl) {
		cJSON_AddStringToObject(root, "returnUrl", auth->returnUrl);
	}

	if (auth->expires) {
		expires = auth->expires;
	} else {
		expires = 3600; // 1小时
	}
    time(&deadline);
    deadline += expires;
	cJSON_AddNumberToObject(root, "deadline", deadline);

	authstr = cJSON_PrintUnformatted(root);
	cJSON_Delete(root);

	return authstr;
}

char* QBox_MakeUpToken(const QBox_AuthPolicy* auth)
{
	char* uptoken;
	char* policy_str;
	char* encoded_digest;
	char* encoded_policy_str;
	char digest[CC_SHA1_DIGEST_LENGTH];
	unsigned int dgtlen = sizeof(digest);

	policy_str = QBox_AuthPolicy_json(auth);
	encoded_policy_str = QBox_String_Encode(policy_str);
	free(policy_str);

	bzero(digest, sizeof(digest));

    CCHmac(kCCHmacAlgSHA1, QBOX_SECRET_KEY, strlen(QBOX_SECRET_KEY), encoded_policy_str, strlen(encoded_policy_str), digest);

	encoded_digest = QBox_Memory_Encode(digest, dgtlen);
	uptoken = QBox_String_Concat(QBOX_ACCESS_KEY, ":", encoded_digest, ":", encoded_policy_str, NULL);
	free(encoded_policy_str);
	free(encoded_digest);

	return uptoken;
}

/*============================================================================*/

