// Colors
// Normal   "\x1B[0m"
// Red      "\x1B[31m"
// Green    "\x1B[32m"
// Yellow   "\x1B[33m"
// Blue     "\x1B[34m"
// CYAN     "\x1B[36m"
// White    "\x1B[37m"
#define DEBUG 1
#define LOG_DBG(x) \
        if(DEBUG) NSLog(@"\x1B[32m[Debug]  \x1B[0m%@", x);
#define LOG_ERR(x) \
        NSLog(@"\x1B[31m[Error]  \x1B[0m%@", x);
#define LOG_OUTPUT(x) \
        NSLog(@"\x1B[36m[Output]  \x1B[0m%@", x);

// TODO: log levels: if arg[x] == D ==> LOG_DBG 