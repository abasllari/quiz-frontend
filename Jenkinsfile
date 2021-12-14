pipeline {
    agent { docker { image 'python:3.10.1-alpine' } }
    stages {
        stage('build') {
            steps {
                sh 'docker login -u abasllari -p 0702618983Da@'
                sh 'docker build -f Dockerfile -t abasllari/myfronttag .'
                sh 'docker push abasllari/myfronttag'
            }
        }
    }
}
