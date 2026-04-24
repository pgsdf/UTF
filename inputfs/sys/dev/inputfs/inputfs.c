/*
 * inputfs: UTF native input substrate kernel module
 *
 * Stage B.1: module skeleton. Loads and unloads cleanly. No device
 * enumeration, no HID parsing, no shared-memory regions, no ioctls.
 * Subsequent Stage B commits add those incrementally.
 *
 * This file is part of the UTF project. See:
 *   docs/UTF_ARCHITECTURAL_DISCIPLINE.md
 *   inputfs/docs/inputfs-proposal.md
 *   inputfs/docs/foundations.md
 *   inputfs/docs/adr/0001-module-charter.md
 *
 * Target: FreeBSD 15.
 */

#include <sys/param.h>
#include <sys/systm.h>
#include <sys/kernel.h>
#include <sys/module.h>
#include <sys/conf.h>

static int
inputfs_modevent(module_t mod, int type, void *data)
{
	int error;

	(void)mod;
	(void)data;
	error = 0;

	switch (type) {
	case MOD_LOAD:
		uprintf("inputfs loaded (Stage B.1 skeleton, no functionality yet)\n");
		break;

	case MOD_UNLOAD:
		uprintf("inputfs unloaded\n");
		break;

	default:
		error = EOPNOTSUPP;
		break;
	}

	return (error);
}

DEV_MODULE(inputfs, inputfs_modevent, NULL);
MODULE_VERSION(inputfs, 1);
