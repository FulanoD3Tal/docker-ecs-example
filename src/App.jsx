import { useState } from 'react';
import reactLogo from './assets/react.svg';
import viteLogo from '/vite.svg';
import './App.css';

function App() {
  const [count, setCount] = useState(0);

  return (
    <>
      <div>
        <a href='https://vitejs.dev' target='_blank' rel='noreferrer'>
          <img src={viteLogo} className='logo' alt='Vite logo' />
        </a>
        <a href='https://react.dev' target='_blank' rel='noreferrer'>
          <img src={reactLogo} className='logo react' alt='React logo' />
        </a>
      </div>
      <h1>Vite + React</h1>
      <div className='card'>
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>Enviroment variables = {import.meta.env.VITE_TEST_VALUE}</p>
      </div>
      <p className='read-the-docs'>
        Click on the Vite and React logos to learn more
      </p>

      <p>
        Et veniam sunt nulla aliqua. Ad velit eu eu ullamco. Cupidatat cupidatat
        qui excepteur voluptate mollit reprehenderit excepteur magna enim
        consequat. Cillum pariatur duis fugiat laborum eiusmod duis exercitation
        reprehenderit tempor velit dolore laboris. Incididunt occaecat eu
        laborum id. Amet commodo adipisicing eu nulla aute dolore culpa.
      </p>

      <p>
        Reprehenderit adipisicing eu non aute mollit laborum Lorem anim
        incididunt non ad sint excepteur. Aliqua ipsum sunt id ut tempor
        incididunt amet officia ex ullamco tempor ad sint. Minim dolore aliquip
        aute officia Lorem reprehenderit do dolor do.
      </p>

      <p>v9</p>
    </>
  );
}

export default App;
