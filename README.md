# RServer Studio on EC2

This is a collection of bash script that allow you to automatically manage and deploy a RStudio server on an EC2 instance.

I have written a simple setup script that sets up and installs a working remote RServer instance on a blank Ubuntu/Amazon Linux EC2 instance with all required dependencies. It also create a new User which is required for RStudio Server. All you have to do is:

```
$ sh install_rstudio_remote.sh
```

You can simple turn on the EC2 instance and open RStudio Server in a browser with just one single command

```
$ rserver start
```

Stopping the RServer is just as simple.

```
$ rserver stop
```

