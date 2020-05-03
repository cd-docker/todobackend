pipeline {
  agent {
    docker {
      alwaysPull true
      image 'continuousdeliverydocker/docker-agent'
      args '-v /var/run/docker.sock:/var/run/docker.sock --mount type=tmpfs,destination=/.docker'
    }
  }
  environment {
    DOCKER_USER     = credentials('docker-user')
    DOCKER_PASSWORD = credentials('docker-password')
    GITHUB_TOKEN    = credentials('github-token')
  }
  stages {
    stage('Build') {
      when {
        changeRequest()
      }
      steps {
        sh 'make build'
      }
    }

    stage('Test') {
      when {
        changeRequest()
      }
      steps {
        sh 'make test'
      }
    }

    stage('Release') {
      when {
        changeRequest()
      }
      steps {
        sh 'make release'
      }
    }

    stage('Publish') {
      when {
        changeRequest()
      }
      steps {
        sh 'make login'
        sh 'make publish'
      }
    }

    stage('Staging') {
      when {
        beforeOptions true
        changeRequest()
      }
      options {
        lock resource: 'todobackend-staging', quantity: 1
      }
      environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION = 'us-west-2'
      }
      steps {
        githubNotify status: 'PENDING', description: 'Deploying to staging', context: 'continuous-integration/jenkins/staging'
        sh 'make deploy/staging'
        sh 'make acceptance/staging'
      }
      post {
        success {
          githubNotify status: 'SUCCESS', description: 'Successfully deployed to staging', context: 'continuous-integration/jenkins/staging'
        }
        failure {
          githubNotify status: 'FAILURE', description: 'Failed deploying to staging', context: 'continuous-integration/jenkins/staging'
        }
      }
    }

    stage('Production') {
      when {
        beforeOptions true
        branch 'master'
      }
      options {
        lock resource: 'todobackend-production', quantity: 1
      }
      environment { 
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION = 'us-west-2'
      }
      steps {
        sh 'make login'
        sh 'make tag'
        sh 'make deploy/production'
      }
    }
  }
  post {
    always {
      junit allowEmptyResults: true, testResults: '**/reports/*.xml'
      sh 'make clean'
      sh 'make logout'
    }
  }
}