# brew install wget
wget -O data/impfquoten.xlsx https://www.rki.de/DE/Content/InfAZ/N/Neuartiges_Coronavirus/Daten/Impfquotenmonitoring.xlsx?__blob=publicationFile
# brew install csvkit
in2csv --sheet Impfungen_proTag data/impfquoten.xlsx > data/per_day.csv
# brew install truncate
tail -n 5 data/per_day.csv | wc -c | xargs -I {} truncate data/per_day.csv -s -{}