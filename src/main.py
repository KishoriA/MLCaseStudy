import exploration
from model import Model
data= exploration.DataLoader('dataset.csv')
data.preprocess()
data.analysis()
model=Model('Logistic Regression')
model.split_dataset()
model.train()
model.save_model()

model=Model('Logistic Regression')
model.load_model()
d={'age':43,'chest_pain':'asympt','rest_bpress':140,'blood_sugar':'f','rest_electro':'normal','max_heart_rate':120,'exercice_angina':'no'}  
res=model.predict_new(d)
print(res)



