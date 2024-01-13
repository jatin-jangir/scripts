FROM postgres:latest

# Copy your Bash script to the container
COPY . .

# Set execute permissions on the script
RUN chmod +x reset-script.sh

# Specify the default command to run when the container starts
CMD ["/bin/bash", "-c", "reset-script.sh"]
