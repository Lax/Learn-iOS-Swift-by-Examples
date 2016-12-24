/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	We define some custom atomics to be used the network so seperate threads at end of commandBuffers can safely increment.
*/

#import "atomics.h"

void __atomic_increment(){
    atomic_fetch_add(&cnt, 1);
}
void __atomic_reset(){
    cnt = ATOMIC_VAR_INIT(0);
}
int __get_atomic_count(){
    return atomic_load(&cnt);
}
