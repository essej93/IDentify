# IDentify

Summary:
Identify is a university project that was worked on by a group of 6 students over the course of a year which was developed with the intent to provide services to businesses which handle different forms of ID cards on a regular basis. It allows business users and their customers to submit images of different forms of ID which is then processed by our Image Processing Server (IPS) where it will handle the skew correction, cropping, card classification and extracting the text using an OCR model. The IPS has been developed in a way that allows easy implementation of new forms of ID if requested by business customers. 

We provide a way for businesses to quickly create an account within the system and start using our product in a matter of minutes, which includes the previously mentioned services as well as a company management system, a way to view previously scanned ID cards, card collection points, QR generation and form generation. 

An API was setup to handle requests for the above mentioned services and encrypts then stores the data in the postgreSQL database. A RabbitMQ server is hosted between the API and IPS to handle all requests going to and from the IPS. The IPS is configured to process 10 images concurrently however this can be increased as long as you have the hardware to handle it.

### Note: This is repository only covers the backend microservices created for the project, the front-end we created was only used to display the functionality.

## Requirements:
- OS: Linux
- GPU: NVIDIA RTX 2080 or newer

The IPS uses machine learning where a model was trained to identify a Card within the image, from there it the image would be cropped and corrected before using zero shot classification/feature matching based on a provided reference image to determine the type of card that has been captured.

![Images/IPS pipeline.png](https://github.com/essej93/IDentify/blob/76eda5cd61bda6c3597bf397644b4cffd39c4899/Images/IPS%20pipeline.png)

### Overall system architecture:

![Images/API to IPS.png](https://github.com/essej93/IDentify/blob/76eda5cd61bda6c3597bf397644b4cffd39c4899/Images/IPS%20pipeline.png)

To run:
To deploy the system, run the deployment.sh script and it should do the rest.
