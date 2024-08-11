# Build vs Buy: Costs

## Case 1

### Amazon Transcribe

- Pricing for 250k minutes 
  - Standard T1, first 250k minutes, $0.024 / minute                = $600
  - Post call analytics T1, first 250k min, $0.03 / minute          = $750
  - Medical call, $0.075 / minute                                   = $1850
- Pricing for 2.5m minutes 
  - Standard T1, first 250k minutes, $0.024 / minute                = $600
  - T2 next 750k minutes, $0.0015                                   = $1125
  - T3 next 4m minutes, $0.00105                                    = $1575
  - Total for 2.5M minutes                                              = $3300


### Amazon Sagemaker

- Pricing for 250k minutes
  - ml.g4dn.xlarge, 15gib, $0.736                                   = $368 (1)
- Pricing for 2.5m minutes
  - ml.g4dn.xlarge, 15gib, $0.736                                   = $3680 (1)


### Engineering Costs 

- Engineering cost to make API calls to Amazing Transcribe, say thats 40 hours at $80/hr = $3200
- Engineering cost to have MLE who has a model they know to use, implement an inference service, probably 100 hours at $120/hr = $12,000

### Conclusion

- The result is very dependent on your organization, but in this example case \
- For only a handful of processing, using the service is simplest and cheapest \
- But then there is a range where the service API requests are more expensive than doing inference yourself on Sagemaker, up to 250k requests \ 
- Until the scaling pricing kicks in for the service in which the price per request is cut by more than half, making it cheaper for 2.5M requests \










(1) 250k minutes, at 50x real time processing = 5000 minutes, assuming model is ~1-1.2gb, can load the model 10 times on 16gb gpu, 5000 minutes / 10 models = 500 minutes * $0.736 = $368
(2) Assumption: the provided API service performs well enough for your specific use case, or your MLE has a model to use and doesn't require model training 
