



Personal Notes:

Phase 2: 


Phase 1: Run the app locally in a container

I found a Hello World Python Flask piece of code on Medium.com to make our app out of. We had to alter the code a little bit so that the output is reachable over a specific port. We're going to choose port 5000. When we run the script, we'll verify it works by opening a new terminal on the EC2 instance and do a test using `curl -i http://localhost:5000`. We'll use `ss -tunlpe` to make sure the app is listening on the right port. 

Lets make a requirement.txt file. We'll put Flask here. After we do that, we can create our Dockerfile. Now, I already have a Dockerfile with a similar Python script in an older lab so I swapped them out. 

Now, we can create the Docker image. We'll name it `tc2-hello-world:latest`. When we run the container, we'll map port 5000 on the host machine to 5000 on the container machine. We can use `docker log tc2-hello-world` to verify the container is listening on the right port. Verify in the EC2 instance that the app is working by doing another curl test after the container is running. Lastly, push all of these files to your GitHub because we'll need them later. 

Don't forget to install Docker and start the service. Also, we'll create the Python virtual environment. We haven't done that in a while. I'll include the commands in a separate file. Make sure you install Python first. 

