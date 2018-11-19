import pandas as pd
import numpy as np 
import coremltools


class DataLoader:
    def __init__(self, filename):
        filename='./data/'+filename        
        self.data=pd.read_csv(filename)
        print('Data Loaded',self.data.head())
        print('Features',self.data.columns)

    def save_file(self, filename):
        filename='./data/'+filename
        self.data.to_csv(filename)
        print('saved file')        

    def preprocess(self):
        data = self.data
        #check if age is in suitable range and replace with mean
        mean_age = data['age'].mean()
        idx=0
        for age in data['age']:     
            if age<10 or age>=100 :
                data.loc[idx,'age']=np.nan      
            idx=idx + 1
 
        #check for missing values in rest BP and max heart rate and replace with mean/median\n",
        median_BP=int(data['rest_bpress'].median())
        mean_heart_rate=int(data['max_heart_rate'].mean())
        data['rest_bpress'].fillna(median_BP,inplace=True)
        data['max_heart_rate'].fillna(median_BP,inplace=True)

        #convert final oucome column i.e disease column to boolean values 1:positive, 0:negative\n",
        data['disease'] = data['disease'].map({'positive': 1, 'negative': 0})

        #check for missing values in  columns and remove the row\n",
        data.dropna(how='any',inplace=True)
        print('Preprocessing Done')
        self.data=data
        print(self.data.head())
        self.save_file('preprocessed.csv')
           
        
       
    def analysis(self):  
        data= self.data
        yes_count=len(data[data['disease']==1])
        no_count=len(data[data['disease']==0])
      
              
        df=data.groupby('disease').median()
        print('median age of patients having disease: ', df['age'][1])
        print('median age of not patients having disease: ',df['age'][0])
        print('median blood pressure of patients having disease: ',df['rest_bpress'][1])
        print('median blood pressure of not patients having disease: ',df['rest_bpress'][0])
        print('median heart rate of patients having disease: ',df['max_heart_rate'][1])
        print('median heart rate of not patients having disease: ',df['max_heart_rate'][0])

    def prepare_data_for_train(self):
        
        x_feats =  self.data.drop(['disease','Unnamed: 0'],1)
        y_feat = self.data['disease']
        y_feat = y_feat.astype('int64')
        output=pd.DataFrame(index=x_feats.index)

        for col,col_data in x_feats.iteritems():
        #convert categorical data to dummy variables/ one hot encoding of the categorical variables\n",
            if col_data.dtype==object:
                col_data=pd.get_dummies(col_data,prefix=col)
            output = output.join(col_data)
        
        return output,y_feat

    
