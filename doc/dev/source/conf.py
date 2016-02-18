import sys
import os
RTD_NEW_THEME = True
extensions = []
templates_path = ['_templates']
source_suffix = '.rst'
master_doc = 'index'
project = u'The LMA Collector Developer Documentation'
copyright = u'2015, Mirantis Inc.'
version = '0.9'
release = '0.9.0'
exclude_patterns = [
]
pygments_style = 'sphinx'
html_theme = 'classic'
html_static_path = ['_static']
htmlhelp_basename = 'LMAcollectordevdoc'
latex_elements = {
}
latex_documents = [
  ('index', 'LMAcollectorDev.tex', u'The LMA Collector Developer Documentation',
   u'Mirantis Inc.', 'manual'),
]
man_pages = [
    ('index', 'lmacollector', u'The LMA Collector Developer Documentation',
     [u'Mirantis Inc.'], 1)
]
texinfo_documents = [
  ('index', 'LMAcollector', u'The LMA Collector Developer Documentation',
   u'Mirantis Inc.', 'LMAcollector', 'One line description of project.',
   'Miscellaneous'),
]
latex_elements = {'classoptions': ',openany,oneside', 'babel':
                  '\\usepackage[english]{babel}'}
