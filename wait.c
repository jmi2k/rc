#include "rc.h"

#include <errno.h>

#include "wait.h"

bool forked = FALSE;

typedef struct Pid Pid;

static struct Pid {
	pid_t pid;
	char *cmd;
	int stat;
	bool alive;
	Pid *n;
} *plist = NULL;

extern pid_t rc_fork() {
	return rc_fork_cmd(NULL);
}

extern pid_t rc_fork_cmd(char *cmd) {
	Pid *new;
	struct Pid *p, *q;
	pid_t pid = fork();

	switch (pid) {
	case -1:
		efree(cmd);
		uerror("fork");
		rc_error(NULL);
		/* NOTREACHED */
	case 0:
		forked = TRUE;
		sigchk();
		for (p = plist; p; p = q) {
			q = p->n;
			efree(p->cmd);
			efree(p);
		}
		plist = 0;
		return 0;
	default:
		new = enew(Pid);
		new->pid = pid;
		new->cmd = cmd;
		new->alive = TRUE;
		new->n = plist;
		plist = new;
		return pid;
	}
}

extern pid_t rc_wait4(pid_t pid, int *stat, bool nointr) {
	char *cmd;
	if ((pid = rc_wait4_cmd(pid, &cmd, stat, nointr)) > 0)
		efree(cmd);
	return pid;
}

extern pid_t rc_wait4_cmd(pid_t pid, char **cmd, int *stat, bool nointr) {
	Pid *r, *prev;

	/* Find the child on the list. */
	for (r = plist, prev = NULL; r != NULL; prev = r, r = r->n)
		if (r->pid == pid)
			break;

	/* Uh-oh, not there. */
	if (r == NULL) {
		errno = ECHILD; /* no children */
		uerror("wait");
		*stat = 0x100; /* exit(1) */
		return -1;
	}

	/* If it's still alive, wait() for it. */
	while (r->alive) {
		int ret;
		Pid *q;

		ret = rc_wait(stat);

		if (ret < 0) {
			if (errno == ECHILD)
				panic("lost child");
			if (nointr)
				continue;
			else
				return ret;
		}

		for (q = plist; q != NULL; q = q->n)
			if (q->pid == ret) {
				q->alive = FALSE;
				q->stat = *stat;
				break;
			}
	}
	*stat = r->stat;
	if (prev == NULL)
		plist = r->n; /* remove element from head of list */
	else
		prev->n = r->n;
	*cmd = r->cmd;
	efree(r);
	return pid;
}

extern List *sgetapids() {
	List *r;
	Pid *p;
	for (r = NULL, p = plist; p != NULL; p = p->n) {
		List *q;
		if (!p->alive)
			continue;
		q = nnew(List);
		q->w = nprint("%d", p->pid);
		q->m = NULL;
		q->n = r;
		r = q;
	}
	return r;
}

extern void waitforall() {
	int stat;
	char *cmd;

	while (plist != NULL) {
		pid_t pid = rc_wait4_cmd(plist->pid, &cmd, &stat, FALSE);
		if (pid > 0) {
			setstatus_cmd(pid, cmd, stat);
			efree(cmd);
		} else {
			set(FALSE);
			if (errno == EINTR)
				return;
		}
		sigchk();
	}
}
