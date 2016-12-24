/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    We define some custom atomics to be used the network so seperate threads at end of commandBuffers can safely increment.
*/

#ifndef atomics_h
#define atomics_h

#import <stdatomic.h>

static atomic_int cnt = ATOMIC_VAR_INIT(0);
void __atomic_increment();
void __atomic_reset();
int __get_atomic_count();

#endif /* atomics_h */
