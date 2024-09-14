#/bin/bash

export TEMPLATE_PATH='/Users/alexis/work/epitadb/docs/latex/template.tex'
export MARKDOWN_PATH='/Users/alexis/work/epitadb/docs/03-solutions/S3-database-design-normalization.md'
export OUTFILE='/Users/alexis/work/epitadb/docs/03-solutions/S3-database-design-normalization.tex'

pandoc -f markdown -t latex --template=$TEMPLATE_PATH  $MARKDOWN_PATH -o $OUTFILE

pandoc -f markdown \
-t latex \
--template=./../latex/template.tex \
S3-database-design-normalization.md   \
-o S3-database-design-normalization.tex

lualatex -interaction=nonstopmode S3-database-design-normalization.tex