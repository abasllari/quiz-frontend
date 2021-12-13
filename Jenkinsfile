pipeline {
  agent { label "linux"  }
  stages {
    stage( "build" ) {
      steps {
        sh """
          docker build -t frontw .
        """
      }
    }
    stage("run") {
      steps {
        sh """
          docker run -d -p 80:80 frontw
        """
      }
    }
  }
}
