import sys
import os

extensions = []
templates_path = ['_templates']
source_suffix = '.rst'
master_doc = 'index'
project = u'The LMA Collector Plugin for Fuel'
copyright = u'2015, Mirantis Inc.'
version = '0.9'
release = '0.9.0'

exclude_patterns = [
    'tests/*.rst'
]

pygments_style = 'sphinx'

html_theme = 'default'
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
