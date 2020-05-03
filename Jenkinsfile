pipeline {
  agent {
    docker {
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
        changeRequest()
      }
      environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION = 'ap-southeast-2'
      }
      steps {
        sh 'make deploy/staging'
      }
    }

    stage('Tag') {
      when {
        branch 'master'
      }
      steps {
        sh 'make login'
        sh 'make tag'
      }
    }

    stage('Production') {
      when {
        branch 'master'
      }
      environment { 
        AWS_ACCESS_KEY_ID = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION = 'ap-southeast-2'
      }
      steps {
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