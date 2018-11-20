import pandas as pd
from sklearn.linear_model import LogisticRegression
from sklearn.svm import LinearSVC
from sklearn.model_selection import train_test_split
from sklearn.externals import joblib
from sklearn.metrics import f1_score,classification_report,confusion_matrix
import numpy as np
import time
from exploration import DataLoader

          


class Model:
    def __init__(self,model_name):     
                
        if model_name=='Logistic Regression':

            self.model=LogisticRegression(multi_class='ovr')
        elif model_name=='SVM':
            self.model=LinearSVC()
        df=DataLoader('preprocessed.csv')

        self.x_feats,self.y_feat = df.prepare_data_for_train()
        #self.x_feats=self.x_feats.drop(['Unnamed: 0'],1)
        self.x_feats=self.x_feats.astype('int64')
        print('features',self.x_feats.columns)

   
        
    def split_dataset(self):
        self.x_train,self.x_test,self.y_train,self.y_test = train_test_split(self.x_feats,self.y_feat,test_size=0.2, random_state=0)
    
    def train(self):    
 
        print("training dataset size",len(self.x_train))
        start=time.time()
        self.model.fit(self.x_train,self.y_train)
        end=time.time()
        y_pred=self.model.predict(self.x_train)
        acc_train=self.model.score(self.x_train,self.y_train)
        y_pred=self.model.predict(self.x_test)
        acc_test=self.model.score(self.x_test,self.y_test)
        print('time for training: ',end-start)
        print('Accuracy of model on train dataset:  {:.2f} %'.format(acc_train*100))
        print('Accuracy of model on test dataset:  {:.2f} %'.format(acc_test*100))
     
        print('CONFUSION MATRIX:')
        print(confusion_matrix(self.y_test,y_pred))
        print('RESULTS')
        self.report=classification_report(y_pred,self.y_test)
        print(self.report)
    
    def predict_new(self, d):
        
        temp=pd.DataFrame(columns=self.x_feats.columns)
    
        for key,value in d.items():
            if(type(value)==str):
                col_name=str(key)+'_'+str(value)
          
                temp.loc[0,col_name]=1
            else:
                temp.loc[0,key]=value
        temp.fillna(0,inplace=True)
        temp=temp.astype('int64')
        print(temp.columns)
       
        res=self.model.predict(temp)
        
        if res>0.5:
           return 'Positive'
        else:
            return 'Negative'

    def save_model(self):
        joblib.dump(self.model,'./models/model.joblib')
    def load_model(self):
        self.model=joblib.load('./models/model.joblib')

    
   
          

    
      
          
       
   




   


