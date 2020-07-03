# -*- encoding: utf-8 -*-
"""
Python Application Template
Licence: GPLv3
"""

import os
from app import app

if __name__ == "__main__":
	port = int(os.environ.get("PORT", 5000))
	app.secret_key = b'_5#y2L"F4Q8z\n\xec]/'
	if os.environ.get("FLASK_ENV", "production") == 'development':
		extra_dirs = ['app', ]
		extra_files = extra_dirs[:]
		for extra_dir in extra_dirs:
			for dirname, dirs, files in os.walk(extra_dir):
				for filename in files:
					filename = os.path.join(dirname, filename)
					if os.path.isfile(filename):
						extra_files.append(filename)
		app.run(host='0.0.0.0', port=port, extra_files=extra_files)
	else:
		app.run(host='0.0.0.0', port=port, threaded=True)
