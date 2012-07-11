#include "conf.h"

/*============================================================================*/

const char* QBOX_ACCESS_KEY				= "<Please apply your access key>";
const char* QBOX_SECRET_KEY				= "<Dont send your secret key to anyone>";

const char* QBOX_REDIRECT_URI			= "<RedirectURL>";
const char* QBOX_AUTHORIZATION_ENDPOINT	= "<AuthURL>";
const char* QBOX_TOKEN_ENDPOINT			= "https://acc.qbox.me/oauth2/token";

int QBOX_PUT_TIMEOUT					= 300000; // 300s = 5m
int QBOX_PUT_CHUNK_SIZE					= 256 * 1024; // 256k
int QBOX_PUT_RETRY_TIMES				= 2;

const char* QBOX_IO_HOST				= "http://iovip.qbox.me";
const char* QBOX_FS_HOST				= "https://fs.qbox.me";
const char* QBOX_RS_HOST				= "http://rs.qbox.me:10100";
const char* QBOX_UP_HOST				= "http://up.qbox.me";

/*============================================================================*/

