import consumer from "channels/consumer"

let slug = window.location.href.split('/').slice(-1)[0];
if (slug && slug.length > 0) {
  const chatChannel = consumer.subscriptions.create({ channel: "ChatChannel", slug: slug }, {
    connected() {
      console.log('connected - chatchannel');
    },

    disconnected() {
      console.log('disconnected - chatchannel');
    },

    received(data) {
      console.log('received', data);
      switch (data.context) {
        case 'message':
          this.appendUserMessage(data.payload);
          break;
        case 'update_score':
          this.updateScore(data.payload)
          break;
      }

    },

    updateScore(data) {
      let playerCard = document.getElementById(data.user_id);
      playerCard.querySelector('p > span').innerHTML = `${data.score} PTS`

      let chat = document.querySelector('.message-container');
      let message = `
        <li>
          <p class="message" style="color: green">
            ${data.name} got it!
          </p>
        </li>
      `;
      chat.insertAdjacentHTML("beforeend", message);
      chat.scrollTo({
        top: chat.scrollHeight,
        left: 0,
        behavior: 'smooth'
      });
    },

    appendUserMessage(data) {
      let chat = document.querySelector('.message-container');
      let message = `
        <li>
          <p class="message">
            <b>${data.author}:</b>
            <span>&nbsp;${data.message}</span>
          </p>
        </li>
      `;
      chat.insertAdjacentHTML("beforeend", message);
      chat.scrollTo({
        top: chat.scrollHeight,
        left: 0,
        behavior: 'smooth'
      });
    },

    appendConnectionMessage(connected) {
      let chat = document.querySelector('.message-container');
      let message = `
        <li>
          <p class="message">
            User has ${connected ? "joined" : "left"} the chat.
          </p>
        </li>
      `;
      chat.insertAdjacentHTML("beforeend", message);
    },
  });

  let chatInput = document.querySelector('#chat_input');
  // better way to access rails controller variable in javascript?
  chatInput.addEventListener('keypress', (event) => {
    let name = [...document.querySelectorAll('.player-card > p > b')].filter((element) => {
      return element.innerText.includes('(you)');
    })[0].innerText.replace(' (you)', '');
    if (event.code === 'Enter') {
      event.preventDefault();
      if (event.target.value.length > 0) {
        let time = parseInt(document.querySelector('#time-remaining').innerHTML);
        console.log('timeremaining', time);
        chatChannel.perform('message', { author: name, message: event.target.value, time: time })
        // chatChannel.send({ author: name, message: event.target.value });
        event.target.value = '';
      }
    }
  });
}
