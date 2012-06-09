generete_from_template
===
Generate rails blank project from csv file having model design information.

Usage
-----
1. Create a rails project.
2. Make template directory, and template/model.csv file.
3. Write model design to template/model.csv.
4. Execute "ruby generate_from_template.rb -o . -t {template erb filename} -c template/model.csv" to generate files.
5. Create some missing view files.
