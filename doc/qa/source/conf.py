import sys
import os

RTD_NEW_THEME = True

extensions = []
templates_path = ['_templates']
source_suffix = '.rst'
master_doc = 'index'
project = u'The LMA Collector Plugin for Fuel'
copyright = u'2015, Mirantis Inc.'
version = '0.8'
release = '0.8.0'

exclude_patterns = []

pygments_style = 'sphinx'

html_theme = 'classic'
html_static_path = ['_static']
htmlhelp_basename = 'LMAcollectortestplandoc'

latex_elements = {
}
latex_documents = [
  ('index', 'LMAcollector.tex', u'The LMA Collector Plugin for Fuel Documentation for QA',
   u'Mirantis Inc.', 'manual'),
]

man_pages = [
    ('index', 'lmacollector', u'The LMA Collector Plugin for Fuel Documentation for QA',
     [u'Mirantis Inc.'], 1)
]

texinfo_documents = [
  ('index', 'LMAcollector', u'The LMA Collector Plugin for Fuel Documentation for QA',
   u'Mirantis Inc.', 'LMAcollector', 'One line description of project.',
   'Miscellaneous'),
]
