import React, { useEffect, useState } from 'react';
import { View, Text } from 'react-native';

const App = () => {
  const [data, setData] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch('http://localhost:3000/api/data');
        const result = await response.json();
        setData(result);
      } catch (error) {
        console.error('Error fetching data', error);
      }
    };
    fetchData();
  }, []);

  return (
    <View>
      {data.map(item => (
        <Text key={item.id}>{item.name} - {item.status}</Text>
      ))}
    </View>
  );
};

export default App;
