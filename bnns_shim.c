#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define DUMMY_CTX_SIZE 4096

__attribute__((visibility("default")))
size_t BNNSGraphContextGetContextSize(void *graph) {
    (void)graph;
    return DUMMY_CTX_SIZE;
}

__attribute__((visibility("default")))
int BNNSGraphContextInitialize(void *context, void *graph) {
    (void)graph;
    if (context) {
        memset(context, 0, DUMMY_CTX_SIZE);
    }
    return 0;
}

__attribute__((visibility("default")))
void *BNNSGraphContextCreate(void *graph) {
    (void)graph;
    return calloc(1, DUMMY_CTX_SIZE);
}

__attribute__((visibility("default")))
void BNNSGraphContextDestroy(void *context) {
    if (context) {
        free(context);
    }
}
