#!/usr/bin/env python
import argparse
import colorama
import time
import tempfile
import watchdog
import logging
import os

import dot_util

# TODO: this script doesn't work yet, oops.

# TODO: use watchdog.
# if __name__ == "__main__":
#     logging.basicConfig(level=logging.INFO,
#                         format='%(asctime)s - %(message)s',
#                         datefmt='%Y-%m-%d %H:%M:%S')
#     path = sys.argv[1] if len(sys.argv) > 1 else '.'
#     event_handler = watchdog.events.LoggingEventHandler()
#     observer = watchdog.Observer()
#     observer.schedule(event_handler, path, recursive=True)
#     observer.start()
#     try:
#         while True:
#             time.sleep(1)
#     except KeyboardInterrupt:
#         observer.stop()
#     observer.join()

class Automake(object):
    def __init__(self, args, parser):
        self.args = args
        self.parser = parser
        self._tmp_files_from = None
        self._tmp_files_from_path = None

    FAIL_STYLE = colorama.Fore.RED
    DONE_STYLE = colorama.Fore.GREEN
    def entr_await_changes_then_run(self):
        with open(self._tmp_files_from_path, 'w') as f:
            files = self.watched_files
            dot_util.log("Watching files:")
            for path in files:
                dot_util.log("  {path}".format(**locals()))
            for path in files:
                f.write(path)
                f.write("\n")
        dot_util.run_cmd("entr {cmd} < {files_from}".format(
            files_from=self._tmp_files_from_path,
            cmd=self.args.cmd
        ))

    def _get_watched_files(self):
        files = []
        if self.args.files_from is not None:
            with open(self.args.files_from) as f:
                for line in f:
                    files.append(line.rstrip())
        elif self.args.files_from_cmd is not None:
            files = dot_util.proc_output_as_list(dot_util.check_output(self.args.files_from_cmd))
        else:
            raise NotImplementedError
        return files

    @property
    def watched_files(self):
        files = [os.path.abspath(f) for f in self._get_watched_files()]
        return files

    def run_cmd(self):
        out, errcode = dot_util.run_cmd(self.args.cmd, shell=True)
        stat = None
        if errcode != 0:
            stat = style(Automake.FAIL_STYLE, "FAILED")
        else:
            stat = style(Automake.DONE_STYLE, "DONE")

        bars = ''.join(50*['='])
        timestamp = self._timestamp()
        print "{stat}: {timestamp} {bars}".format(**locals())

    def _timestamp(self):
        return time.strftime("%c")

    def _setup(self):
        fd, path = tempfile.mkstemp()
        os.close(fd)
        self._tmp_files_from = open(path, 'w')
        self._tmp_files_from_path = path

    def _cleanup(self):
        if self._tmp_files_from is not None:
            self._tmp_files_from.close()
            if not self.args.debug:
                os.remove(self._tmp_files_from_path)

    def main(self):
        try:
            self._setup()
            while True:
                self.entr_await_changes_then_run()
                # self.await_changes()
                # self.run_cmd()
        finally:
            self._cleanup()


def style(term_style, txt,):
    return term_style + txt + colorama.Style.RESET_ALL

def main():
    parser = argparse.ArgumentParser("Re-run commands in response to project file changes")
    parser.add_argument("--cmd", default="./make.sh", required=True,
                        help="Run this command when project file changes are detected")
    parser.add_argument("--files-from",
                        help="if any files listed in this file change, re-run --cmd")
    parser.add_argument("--files-from-cmd",
                        help="run this cmd to get a list of files to watch")
    parser.add_argument("--debug", action='store_true',
                        help="debug")
    args = parser.parse_args()

    if args.files_from is None and args.files_from_cmd is None:
        parser.error("Need --files-from or --files-from-cmd")

    if args.files_from is not None and not os.path.exists(args.files_from):
        parser.error("Couldn't --files-from")

    automake = Automake(args, parser)
    automake.main()

if __name__ == '__main__':
    main()