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
  }
  stages {
    stage('Build') {
      when {
        allOf {
          not { branch 'master' }
          changeRequest()
        }
      }
      steps {
        sh 'make build'
      }
    }

    stage('Test') {
      when {
        allOf {
          not { branch 'master' }
          changeRequest()
        }
      }
      steps {
        sh 'make test'
      }
    }

    stage('Release') {
      when {
        allOf {
          not { branch 'master' }
          changeRequest()
        }
      }
      steps {
        sh 'make release'
      }
    }

    stage('Publish') {
      when {
        allOf {
          not { branch 'master' }
          changeRequest()
        }
      }
      steps {
        sh 'make login'
        sh 'make publish'
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
  }
  post {
    always {
      junit allowEmptyResults: true, testResults: '**/reports/*.xml'
      sh 'make clean'
      sh 'make logout'
    }
  }
}