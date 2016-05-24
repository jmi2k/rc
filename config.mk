### Which line editing library?
### none:
#	EDIT_SRC := edit-null.c
#	EDIT_LIB :=
### bsd/libedit:
#	EDIT_SRC := edit-edit.c
#	EDIT_LIB := -ledit
### editline:
#	EDIT_SRC := edit-editline.c
#	EDIT_LIB := -leditline
### readline:
	EDIT_SRC := edit-readline.c
	EDIT_LIB := -lreadline
### vrl:
#	EDIT_SRC := edit-vrl.c
#	EDIT_LIB := -lvrl

### Which system.c?
### bsd:
#	SYSTEM_SRC := system-bsd.c
### default:
	SYSTEM_SRC := system.c

### if RC_ADDON defined in config.h:
#	ADDON_SRC := addon.c

### if HASH_BANG not defined in config.h:
#	EXECVE_SRC := execve.c

