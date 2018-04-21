pipeline {
  agent any
  stages {
    stage('Awesome stage') {
      parallel {
        stage('Awesome stage') {
          steps {
            echo 'Hello World'
          }
        }
        stage('Cool Stage') {
          steps {
            sleep 2
          }
        }
      }
    }
  }
}