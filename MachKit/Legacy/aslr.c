#include <stdio.h>
#include <stdlib.h>
#include "Attach.h"

int main(int argc, const char * argv[]) {
	if(argc != 2) {
		fprintf(stderr, "Usage: get_aslr pid\n");
		return 1;
	}
	
	if(getuid() != 0) {
		fprintf(stderr, "If you see any errors, you should probably run this as root.\n");
	}
	
	pid_t pid = (pid_t)strtol(argv[1], NULL, 0);
	
	mach_vm_address_t main_address;
	if(find_main_binary(pid, &main_address) != KERN_SUCCESS) {
		fprintf(stderr, "Failed to find address of header!\n");
		return 1;
	}
	
	uint64_t aslr_slide;
	if(get_image_size(main_address, pid, &aslr_slide) == -1) {
		fprintf(stderr, "Failed to find ASLR slide!\n");
		return 1;
	}
	
	printf("0x%llx\n", aslr_slide);
	
	return 0;
}

