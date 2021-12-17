pipeline {
    agent any
    stages {
        stage('build') {
            steps {
                sh 'docker login -u abasllari -p 070261893Da@'
                sh 'docker build -f Dockerfile -t abasllari/myfronttag .'
                sh 'docker push abasllari/myfronttag'
            }
         }
        stage('deploy')
        echo "new sategssssss"
    }
}
