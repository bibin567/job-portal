provider "aws" {
  region = "us-east-1" # Change this to your desired AWS region
}

resource "aws_security_group" "web_server_sg" {
  name        = "web-server-sg"
  description = "Security group for the web server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict the source IP range for security reasons
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict the source IP range for security reasons
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict the source IP range for security reasons
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t2.micro"
  key_name               = "new"
  vpc_security_group_ids = [aws_security_group.web_server_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y unzip
              sudo apt-get install -y apache2 libapache2-mod-php php-mysql

              # Install git
              sudo apt-get install -y git

              # Disable the default Apache virtual host
              sudo a2dissite 000-default

              # Clone the GitHub repository
              git clone https://github.com/bibin567/job-site.git /var/www/html/job_portal

              # Create a new Apache virtual host for the PHP job portal
              echo "<VirtualHost *:80>
                ServerAdmin webmaster@localhost
                DocumentRoot /var/www/html/job_portal
                ErrorLog /var/log/apache2/error.log
                CustomLog /var/log/apache2/access.log combined

                <Directory /var/www/html/job_portal>
                  Options Indexes FollowSymLinks
                  AllowOverride All
                  Require all granted
                </Directory>

                # Set index.php as the default index page
                DirectoryIndex login.php

              </VirtualHost>" | sudo tee /etc/apache2/sites-available/job_portal.conf

              # Enable the new Apache virtual host
              sudo a2ensite job_portal

              # Reload Apache to apply the changes
              sudo service apache2 reload

              # Install MySQL Server (You will be prompted to set the MySQL root password)
              sudo apt-get install -y mysql-server

              # Wait for MySQL to start
              sleep 10

              # Create the jobportal database
              sudo mysql -u root -e "CREATE DATABASE IF NOT EXISTS jobportal;"

              # Import the jobportal.sql file into the database
              sudo mysql -u root jobportal < /var/www/html/job_portal/jobportal.sql

              # Create a new MySQL user and grant privileges to it
              sudo mysql -u root -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin';"
              sudo mysql -u root -e "GRANT ALL PRIVILEGES ON jobportal.* TO 'admin'@'localhost';"
              sudo mysql -u root -e "FLUSH PRIVILEGES;"

              EOF

  tags = {
    Name = "JobPortalInstance"
  }
}











