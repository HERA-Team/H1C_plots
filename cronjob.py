#! /usr/bin/env python
# -*- mode: python; coding: utf-8 -*-
# Copyright 2017 the HERA Collaboration
# Licensed under the MIT License

import os.path
import subprocess
import sys
from hera_librarian import LibrarianClient

connection_name = 'local'

# Search for sessions that are:
#
# 1. Unprocessed, as evidenced by the fact that none of its associated
#    files have a 'nightlynb.processed' event
# 2. Either:
#       a. Standard session that is fully or almost fully uploaded, as
#          evidenced by there being lots of files on the Librarian.
#    or
#       b. Older than a few days, suggesting that we should just go
#          ahead and process whatever we've got.

search = '''
{
   "no-file-has-event": "nightlynb.processed",
   "or": {
      "age-greater-than": 3,
      "num-files-greater-than": 2000
   }
}
'''

def main():
    cl = LibrarianClient(connection_name)

    sessions = cl.search_sessions(search)['results']

    if not len(sessions):
        return # Nothing to do.

    # Just pick one to process and submit the job that will
    # actually crunch it.

    sessid = sessions[0]['id']

    plots_dir = os.path.dirname(sys.argv[0])
    plot_script = os.path.join(plots_dir, 'run_notebook.sh')

    env = dict(os.environ)
    env['sessid'] = str(sessid)

    subprocess.check_call(
        ['qsub', '-V', '-q', 'hera', plot_script],
        shell = False,
        env = env
    )


if __name__ == '__main__':
    main()
