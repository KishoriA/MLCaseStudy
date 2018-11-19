import hug


@hug.post('/api/', versions=1)
def serve(**kargs):

    features = {}

    for k, v in kargs.items():
        features.update({k : v})

    return hug.output_format.json({'output': features})
        
