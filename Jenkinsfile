pipeline {
  agent any
  stages {
    stage('Awesome stage') {
      parallel {
        stage('Awesome stage') {
          steps {
            echo 'Hello World'
            waitUntil() {
              sleep 1
            }

          }
        }
        stage('Cool Stage') {
          steps {
            sleep 2
          }
        }
      }
    }
    stage('') {
      steps {
        timestamps()
      }
    }
  }
}