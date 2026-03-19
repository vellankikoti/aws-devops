#!/bin/bash
echo "Generating load on Sock Shop front-end..."
echo "Press Ctrl+C to stop"
FRONTEND=$(kubectl get svc front-end -n sock-shop -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "localhost")
while true; do
  curl -s "http://${FRONTEND}/" > /dev/null
  curl -s "http://${FRONTEND}/catalogue" > /dev/null
  curl -s "http://${FRONTEND}/cart" > /dev/null
  sleep 0.1
done
