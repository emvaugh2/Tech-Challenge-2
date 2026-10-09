



Personal Notes:


Phase 4: Manual Flask Deployment with Helm

10/08/2026

Okay lets get this started! We'll clone my GitHub repo so I can access my Hello Cruel World app. Then, build the image. Verify that it's there. Then, we need to authenticate Docker to ECR using the commands listed in the notes. Now we need to tag our image and push it to the ECR. I was running into an issue with the docker push command. It wasn't finishing the push to the ECR. I was missing the `sudo` on the docker login command so I had to change that. Silly mistakes!

Lets create our custom namespace for this challenge. We'll name it `tc2`. Then, we'll create out helm chart. This will generate all the sub-directories we need for our Helm deployment. We'll need to alter some of these files. We'll be altering our Charts.yaml and values.yaml files. We'll remove our tests directory and our httproute.yaml file. I ran into an error message with the values.yaml file. There were a few parts where I left the {} brackets where I added values. I had to remove the brackets since I believe that denotes an empty space. 

Then I ran into an issue with the Charts.yaml file. Apparently Helm didn't like that we still had the NOTES.txt file. I removed it. There was so much troubleshooting after this. I don't even remember each part. We'll just have to go back over this section but we finally got it to work. 

In order to push to my GitHub repo from my EC2 instance, I had to generate a fine-used token with the permissions of Content for Read & Write. That was also a quick headache. Had to side-step that. 

Phase 3: EKS cluster setup and add-ons


Clarification notes:

A service account gives a workload running inside Kubernetes an identity. Think of it like a non-human admin. It's assuming an IAM role. The annotate command added metadata to the service account. It tells EKS that the pods using this service account should be allowed to assume this AWS IAM role. This allows EKS to inject AWS role (and token information) into the Pod.

The rollout command waits for the deployment to finish. I guess it's kind of like a status loading bar. It actively waits until it's done rolling out. 

A helm repo contains specific Helm charts and an index (manual) describing the available charts and versions. We needed this for the AWS EKS repo for the AWS load balancer controller. The charts are templates that create these types of services so that's why we have to install these repos. You don't want to create these deployment.yaml files from scratch, right? Then use the repo and the charts. 

`kube-system` is a namespace. It's reservered for cluster-level system components created by K8s or installed to operate the cluster. So the big ones like Cluster DNS, metrics, load balancer automation, node autoscaling, etc support the entire system. Your hello cruel world application is just one part of the system so it should be in another namespace. 


10/8/2026

So, we'll start by deploying our Terraform infrastructure again. We'll validate that both the cluster and worker nodes have been created. I'll include the `aws eks` commands in the notes. We're going to use the Jenkins server as the mgmt jumpbox as well to run all of our commands. When you log into your Jenkins server, run `aws sts get-caller-identity` to make sure you have the proper privileges. You can install all the CLIs afterwards. I ran the `describe-nodegroup` command and received an unauthorized error message. We needed to update the permissions on our Jenkins server IAM role. I saved those changes. When then ran into a time-out issue when retrieving the pods and nodes. The traffic from the Jenkins server to the EKS API was being blocked. We needed to create an ingress rule on port 443 from the Jenkins server to the EKS automatically created SG. I added this block to the security.tf file in Terraform. Once I deployed, we were able to confirm the proper pods (aws-node-lb, two coredns pods, and kube-proxy). Now we're cooking

Lets create the Metrics Server. I put all the commands in the notes. You should be able to see the metrics of the pods and nodes if you use the `kubectl top` command. The rollout command ********************** . Now, lets create the AWS Load Balancer. We need to install it and then verify it. It will watch the K9s Ingress and then provision an AWS Application Load Balancer. I put all the commands in the notes as well as there are a lot of them. Once you verify with the get deployment and get pods commands, we can move onto the Autoscaler. We did run into a few IAM issues when it came to retrieving basic AWS information so I also updated the iam.tf file for TF. 

Lets do the Autoscaler. I have all the commands listed in the notes as well since there are A LOT. After everything was said and done, we ran into two failures regarding the Autoscaler missing the AWS region. We're going to fix that. We need to redeploy our `helm (upgrade) cluster-autoscaler` command and hardcode our region and cloud provider for some reason. Once we did that, our error messages cleared. We ran our last checks with out get commands and verified everything is up and running! That completes this phase. 

10/07/2026

- Install Metrics Server
- AWS Load Balancer Controller
- Cluster Autoscaler


Phase 2: Terraform the AWS environment. 


10/07/2026

We're going through each file and verifying that it's correct. The providers.tf file is good. We're adding a few things to the networking.tf file. Just a reminder, the Jenkins server, NAT Gateway, and ALB will go in the public subnets. The EKS worker nodes and application pods will go in the private subnets. We added AWS DNS support in our VPC block. I'll have to figure out why this is important exactly. The answer was pretty vague AI gave me. 

We also updated the public subnets to allow the AWS Load Balancer Controller to figure out which subnets the ALB should use. We put this in the tag section. Never once seen this before. Apparently the Kubernetes tag tells the controller that you can use this for the AWS load balancer. 

For the security group (SG), we just kept the Jenkins SG. We're allowing SSH and port 8080 traffic and that's really it. The resources will handle a lot of their own networking and SG settings such as the EKS cluster and the AWS Load Balancer Controller. 

The ECR was pretty straightforward. I only changed the name from my previous deployments. I also changed the lifecycle policy to only hold images for 5 days and not 14. 

I confess. I had AI completely create the IAM roles outside of the Control and Worker EKS roles. I did not understand the Autoscaler, Load Balancer Controller, or Jenkins server roles. Well, I can understand the Jenkins one but the other two, I just couldn't find any resources on this and I'm tired. I'll review it later. 

I ran the usual terraform fmt, validate, plan and apply. After about 15 minutes, all 44 resources deployed. How nice! Lets move on to the next phase. 

10/06/2026

The overall infrastructure goal is to run our container on an Elastic Kubernetes Cluster (EKS) that utilizes autoscaling and an Application Load Balancer (ALB). We need to create everything that supports this environment. We'll need a VPC with private and public subnets, route tables, internet gateway (IGW), and a NAT gateway. 

Our EKS nodes will be in the private subnets. We need to also create an Elastic Container Registry (ECR) for the image. Then, we'll create our Jenkins EC2 server and our security group. 

Our final phase will be handling all of AWS's IAM roles. We need a role for the EKS cluster, EKS worker group, Jenkins EC2 role, Jenkins EKS access entry, and on the newer side, roles for the AWS LB controller and cluster autoscaler. 


Phase 1: Run the app locally in a container

I found a Hello World Python Flask piece of code on Medium.com to make our app out of. We had to alter the code a little bit so that the output is reachable over a specific port. We're going to choose port 5000. When we run the script, we'll verify it works by opening a new terminal on the EC2 instance and do a test using `curl -i http://localhost:5000`. We'll use `ss -tunlpe` to make sure the app is listening on the right port. 

Lets make a requirement.txt file. We'll put Flask here. After we do that, we can create our Dockerfile. Now, I already have a Dockerfile with a similar Python script in an older lab so I swapped them out. 

Now, we can create the Docker image. We'll name it `tc2-hello-world:latest`. When we run the container, we'll map port 5000 on the host machine to 5000 on the container machine. We can use `docker log tc2-hello-world` to verify the container is listening on the right port. Verify in the EC2 instance that the app is working by doing another curl test after the container is running. Lastly, push all of these files to your GitHub because we'll need them later. 

Don't forget to install Docker and start the service. Also, we'll create the Python virtual environment. We haven't done that in a while. I'll include the commands in a separate file. Make sure you install Python first. 

Ran into a `git add .` issue. I think when I cloned my empty repo, it created another Tech-Challenge-2 folder within the original Tech-Challenge-2 folder and it had it's own .git directory. I had to delete that before I was able to add my files. 